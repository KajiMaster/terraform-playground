"""
Enterprise E-commerce Microservice
FastAPI-based product catalog and order management system
"""

import asyncio
import time
import uuid
from contextlib import asynccontextmanager
from datetime import datetime, timedelta
from typing import List, Optional

import structlog
from fastapi import FastAPI, HTTPException, Depends, BackgroundTasks, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, Response, HTMLResponse
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from pydantic import BaseModel, Field
from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, Boolean, ForeignKey, Text
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship, selectinload
from sqlalchemy.future import select
from sqlalchemy.pool import QueuePool
import psutil
import os
import boto3
from functools import lru_cache

# Configure structured logging
structlog.configure(
    processors=[
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.add_log_level,
        structlog.processors.StackInfoRenderer(),
        structlog.dev.set_exc_info,
        structlog.processors.JSONRenderer()
    ],
    wrapper_class=structlog.make_filtering_bound_logger(20),  # INFO level
    logger_factory=structlog.PrintLoggerFactory(),
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()

# Prometheus metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'HTTP request duration')
DB_QUERY_DURATION = Histogram('db_query_duration_seconds', 'Database query duration')

# Database Models
Base = declarative_base()

class Contact(Base):
    __tablename__ = "contacts"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    email = Column(String(100), nullable=False, unique=True)
    phone = Column(String(20))
    created_at = Column(DateTime, default=datetime.utcnow)

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    username = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    orders = relationship("Order", back_populates="user")

class Category(Base):
    __tablename__ = "categories"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, index=True, nullable=False)
    description = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    products = relationship("Product", back_populates="category")

class Product(Base):
    __tablename__ = "products"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), index=True, nullable=False)
    description = Column(Text)
    price = Column(Float, nullable=False)
    stock_quantity = Column(Integer, default=0)
    category_id = Column(Integer, ForeignKey("categories.id"))
    sku = Column(String(100), unique=True, index=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    category = relationship("Category", back_populates="products")
    order_items = relationship("OrderItem", back_populates="product")

class Order(Base):
    __tablename__ = "orders"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    order_number = Column(String(100), unique=True, index=True)
    total_amount = Column(Float, nullable=False)
    status = Column(String(50), default="pending")  # pending, processing, shipped, delivered, cancelled
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    user = relationship("User", back_populates="orders")
    items = relationship("OrderItem", back_populates="order")

class OrderItem(Base):
    __tablename__ = "order_items"
    
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"))
    product_id = Column(Integer, ForeignKey("products.id"))
    quantity = Column(Integer, nullable=False)
    unit_price = Column(Float, nullable=False)
    
    order = relationship("Order", back_populates="items")
    product = relationship("Product", back_populates="order_items")

# Pydantic Models
class ProductBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    price: float = Field(..., gt=0)
    stock_quantity: int = Field(default=0, ge=0)
    category_id: int
    sku: str = Field(..., min_length=1, max_length=100)

class ProductCreate(ProductBase):
    pass

class ProductResponse(ProductBase):
    id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class ContactBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    email: str = Field(..., min_length=1, max_length=100)
    phone: Optional[str] = Field(None, max_length=20)

class ContactCreate(ContactBase):
    pass

class ContactResponse(ContactBase):
    id: int
    created_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

class CategoryBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = None

class CategoryCreate(CategoryBase):
    pass

class CategoryResponse(CategoryBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

class OrderItemResponse(BaseModel):
    id: int
    product_id: int
    quantity: int
    unit_price: float
    
    class Config:
        from_attributes = True

class OrderResponse(BaseModel):
    id: int
    order_number: str
    total_amount: float
    status: str
    created_at: datetime
    items: List[OrderItemResponse]
    
    class Config:
        from_attributes = True

# Configuration
class Settings:
    def __init__(self):
        self.database_url = self._get_database_url()
        self.secret_key = os.getenv("SECRET_KEY", "your-secret-key-here")
        
    def _get_database_url(self):
        # For MySQL to match the infrastructure
        host = os.getenv("DB_HOST", "localhost")
        user = os.getenv("DB_USER", "tfplayground_user")
        password = self._get_db_password()
        database = os.getenv("DB_NAME", "tfplayground")
        
        return f"mysql+aiomysql://{user}:{password}@{host}:3306/{database}"
    
    @lru_cache(maxsize=1)
    def _get_db_password(self):
        # For local development, use environment variable
        if os.environ.get('DB_PASSWORD'):
            return os.environ.get('DB_PASSWORD')
        
        # For AWS deployment, use Parameter Store
        try:
            region = os.environ.get('AWS_REGION', 'us-east-2')
            client = boto3.client('ssm', region_name=region)
            parameter_name = '/tf-playground/all/db-pword'
            response = client.get_parameter(
                Name=parameter_name,
                WithDecryption=True
            )
            return response['Parameter']['Value']
        except Exception as e:
            logger.error("Failed to get password from Parameter Store", error=str(e))
            return "defaultpassword"

settings = Settings()

# Database setup
engine = create_async_engine(
    settings.database_url,
    poolclass=QueuePool,
    pool_size=20,
    max_overflow=30,
    pool_pre_ping=True,
    pool_recycle=3600,
    echo=False
)

AsyncSessionLocal = async_sessionmaker(
    engine, 
    class_=AsyncSession, 
    expire_on_commit=False
)

# Dependency to get database session
async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()

# Application lifecycle
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Starting up application")
    
    # Create tables (in production, use Alembic migrations)
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        logger.info("Database tables created successfully")
    except Exception as e:
        logger.warning("Failed to create database tables", error=str(e))
        logger.info("Application will start without database initialization")
    
    logger.info("Application startup complete")
    yield
    
    # Shutdown
    logger.info("Shutting down application")
    await engine.dispose()

# FastAPI app
app = FastAPI(
    title="Enterprise E-commerce API",
    description="A realistic e-commerce microservice for enterprise testing",
    version="1.0.0",
    lifespan=lifespan
)

# Jinja2 templates setup
templates = Jinja2Templates(directory="templates")

# Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start_time = time.time()
    
    response = await call_next(request)
    
    duration = time.time() - start_time
    REQUEST_DURATION.observe(duration)
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code
    ).inc()
    
    return response

# Health check endpoints
@app.get("/health")
async def health_check():
    """Comprehensive health check"""
    try:
        # Database check
        async with AsyncSessionLocal() as session:
            start_time = time.time()
            await session.execute(select(1))
            db_duration = time.time() - start_time
            DB_QUERY_DURATION.observe(db_duration)
        
        # System resources
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        return {
            "status": "healthy",
            "timestamp": datetime.utcnow().isoformat(),
            "container_id": os.environ.get('HOSTNAME', 'unknown'),
            "deployment_color": os.environ.get('DEPLOYMENT_COLOR', 'unknown'),
            "checks": {
                "database": {"status": "ok", "response_time_ms": round(db_duration * 1000, 2)},
                "memory_usage": {"percent": memory.percent, "available_gb": round(memory.available / 1024**3, 2)},
                "disk_usage": {"percent": disk.percent, "free_gb": round(disk.free / 1024**3, 2)}
            }
        }
    except Exception as e:
        logger.error("Health check failed", error=str(e))
        raise HTTPException(status_code=503, detail=f"Health check failed: {str(e)}")

@app.get("/health/simple")
async def simple_health_check():
    """Simple health check for load balancer - no database required"""
    return {
        "status": "ok",
        "timestamp": datetime.utcnow().isoformat(),
        "container_id": os.environ.get('HOSTNAME', 'unknown')
    }

@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)

# API Routes
@app.get("/", response_model=dict)
async def root():
    """API information"""
    return {
        "service": "Enterprise E-commerce API",
        "version": "1.0.0",
        "timestamp": datetime.utcnow().isoformat(),
        "container_id": os.environ.get('HOSTNAME', 'unknown'),
        "deployment_color": os.environ.get('DEPLOYMENT_COLOR', 'unknown')
    }

@app.get("/web")
async def web_root():
    """Hello World HTML page"""
    html_content = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Hello World - E-commerce API</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
            .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            h1 { color: #333; text-align: center; }
            .api-info { background: #f8f9fa; padding: 20px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #007bff; }
            .endpoints { margin-top: 30px; }
            .endpoint-list { list-style: none; padding: 0; }
            .endpoint-list li { margin: 10px 0; }
            .endpoint-list a { color: #007bff; text-decoration: none; padding: 8px 16px; background: #e9ecef; border-radius: 5px; display: inline-block; }
            .endpoint-list a:hover { background: #007bff; color: white; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Hello World! 🌍</h1>
            <p style="text-align: center; color: #666; font-size: 1.2em;">Welcome to the Enterprise E-commerce API</p>
            
            <div class="api-info">
                <h2>API Information</h2>
                <p><strong>Service:</strong> Enterprise E-commerce API</p>
                <p><strong>Version:</strong> 1.0.0</p>
                <p><strong>Status:</strong> Running</p>
                <p><strong>Container ID:</strong> """ + os.environ.get('HOSTNAME', 'unknown') + """</p>
                <p><strong>Deployment Color:</strong> """ + os.environ.get('DEPLOYMENT_COLOR', 'unknown') + """</p>
            </div>
            
            <div class="endpoints">
                <h2>Available Endpoints</h2>
                <ul class="endpoint-list">
                    <li><a href="/">JSON API</a></li>
                    <li><a href="/jinja">Jinja2 Template</a></li>
                    <li><a href="/health">Health Check</a></li>
                    <li><a href="/docs">API Documentation</a></li>
                    <li><a href="/products">Products</a></li>
                    <li><a href="/contacts">Contacts</a></li>
                </ul>
            </div>
        </div>
    </body>
    </html>
    """
    
    return HTMLResponse(content=html_content)

@app.get("/jinja")
async def jinja_root(request: Request):
    """Hello World with Jinja2 template"""
    return templates.TemplateResponse("index.html", {
        "request": request,
        "service": "Enterprise E-commerce API",
        "version": "1.0.0",
        "container_id": os.environ.get('HOSTNAME', 'unknown'),
        "deployment_color": os.environ.get('DEPLOYMENT_COLOR', 'unknown'),
        "timestamp": datetime.utcnow().isoformat()
    })





# Contacts
@app.get("/contacts", response_model=List[ContactResponse])
async def get_contacts(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db)
):
    """Get all contacts with pagination"""
    result = await db.execute(
        select(Contact).offset(skip).limit(limit)
    )
    contacts = result.scalars().all()
    
    logger.info("Contacts retrieved from database", count=len(contacts))
    return contacts

@app.post("/contacts", response_model=ContactResponse)
async def create_contact(
    contact: ContactCreate,
    db: AsyncSession = Depends(get_db)
):
    """Create a new contact"""
    db_contact = Contact(**contact.dict())
    db.add(db_contact)
    await db.commit()
    await db.refresh(db_contact)
    
    logger.info("Contact created", contact_id=db_contact.id, name=db_contact.name)
    return db_contact

@app.get("/contacts/{contact_id}", response_model=ContactResponse)
async def get_contact(contact_id: int, db: AsyncSession = Depends(get_db)):
    """Get a specific contact by ID"""
    result = await db.execute(
        select(Contact).where(Contact.id == contact_id)
    )
    contact = result.scalar_one_or_none()
    
    if not contact:
        raise HTTPException(status_code=404, detail="Contact not found")
    
    return contact

# Categories
@app.post("/categories", response_model=CategoryResponse)
async def create_category(
    category: CategoryCreate,
    db: AsyncSession = Depends(get_db)
):
    """Create a new product category"""
    db_category = Category(**category.dict())
    db.add(db_category)
    await db.commit()
    await db.refresh(db_category)
    
    logger.info("Category created", category_id=db_category.id, name=db_category.name)
    return db_category

@app.get("/categories", response_model=List[CategoryResponse])
async def get_categories(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db)
):
    """Get all categories with pagination"""
    result = await db.execute(
        select(Category).offset(skip).limit(limit)
    )
    categories = result.scalars().all()
    
    logger.info("Categories retrieved from database", count=len(categories))
    return categories

# Products
@app.post("/products", response_model=ProductResponse)
async def create_product(
    product: ProductCreate,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db)
):
    """Create a new product"""
    db_product = Product(**product.dict())
    db.add(db_product)
    await db.commit()
    await db.refresh(db_product)
    
    # Add background task to update search index
    background_tasks.add_task(update_search_index, db_product.id)
    
    logger.info("Product created", product_id=db_product.id, sku=db_product.sku)
    return db_product

@app.get("/products", response_model=List[ProductResponse])
async def get_products(
    skip: int = 0,
    limit: int = 100,
    category_id: Optional[int] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    db: AsyncSession = Depends(get_db)
):
    """Get products with filtering and pagination"""
    query = select(Product).options(selectinload(Product.category))
    
    if category_id:
        query = query.where(Product.category_id == category_id)
    if min_price:
        query = query.where(Product.price >= min_price)
    if max_price:
        query = query.where(Product.price <= max_price)
    
    query = query.where(Product.is_active == True).offset(skip).limit(limit)
    
    result = await db.execute(query)
    products = result.scalars().all()
    
    logger.info("Products retrieved", count=len(products), filters={
        "category_id": category_id,
        "min_price": min_price,
        "max_price": max_price
    })
    return products

@app.get("/products/{product_id}", response_model=ProductResponse)
async def get_product(product_id: int, db: AsyncSession = Depends(get_db)):
    """Get a specific product by ID"""
    result = await db.execute(
        select(Product).where(Product.id == product_id)
    )
    product = result.scalar_one_or_none()
    
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    return product

# Background task example
async def update_search_index(product_id: int):
    """Simulate updating a search index in the background"""
    await asyncio.sleep(2)  # Simulate work
    logger.info("Search index updated", product_id=product_id)

# Add a CPU-intensive endpoint for load testing
@app.get("/compute/fibonacci/{n}")
async def compute_fibonacci(n: int):
    """CPU-intensive endpoint for performance testing"""
    if n > 40:
        raise HTTPException(status_code=400, detail="Number too large")
    
    def fib(x):
        if x <= 1:
            return x
        return fib(x-1) + fib(x-2)
    
    start_time = time.time()
    result = fib(n)
    duration = time.time() - start_time
    
    return {
        "input": n,
        "result": result,
        "computation_time_ms": round(duration * 1000, 2),
        "container_id": os.environ.get('HOSTNAME', 'unknown')
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)