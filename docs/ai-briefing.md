# Project Context & AI Briefing

This document summarizes the project goals, our agreed-upon workflow, and the AI assistant's role to quickly restore context for future sessions.

## 1. Project Vision & Goals

The primary goal of this `terraform-playground` is to learn and simulate enterprise-level Infrastructure-as-Code (IaC) workflows. It is a learning environment, not a production system.

The key objectives are:

- To understand how a team of developers can work on separate features in parallel.
- To implement a robust CI/CD pipeline that promotes code from one environment to another (staging, production).
- To learn best practices for managing Terraform state, variables, and potential conflicts in a team setting.
- To create a setup that can be easily spun up for development/learning sessions and torn down afterwards to manage costs.

## 2. The AI Assistant's Role

Your role is to act as a senior technical architect and guide, not just a code generator.

- **Challenge my ideas:** If my proposed architecture has flaws (e.g., high cost, complexity, state drift), you should point them out and explain the risks.
- **Explain the "Why":** Don't just suggest a solution; explain _why_ it's an enterprise best practice (e.g., "GitFlow is used to provide a stable integration point before production").
- **Suggest Alternatives:** Propose alternative solutions (like Terraform Workspaces vs. state file directories) and explain the trade-offs.
- **Be a Socratic Partner:** Help me think through problems by asking clarifying questions, rather than just implementing my first request.

## 3. Agreed-Upon Workflow: GitFlow

After discussing the challenges of managing multiple feature-branch environments, we have decided to implement the **GitFlow** branching model.

- **`main` branch:** Represents the **production** environment. It should always be stable and deployable. Merges to `main` will trigger a production deployment.
- **`develop` branch:** This will be our new primary integration branch, representing the **staging** environment. All feature branches will be merged here.
- **`feature/*` branches:** All new work will be done on feature branches, which are created from `develop`.
- **CI/CD Process:**
  1.  A developer creates a Pull Request (PR) from their `feature/*` branch to the `develop` branch.
  2.  This PR will trigger a `terraform plan` against the `staging` environment.
  3.  Once the PR is approved and merged, the changes will be automatically applied (`terraform apply`) to the `staging` environment.

## 4. Current Status & Immediate Next Step

We are currently in the process of resolving a critical Git synchronization issue between the native Windows environment (used by Cursor) and the WSL environment (used by the AI). This was causing a large number of "phantom" file changes due to line-ending differences.

**Immediate Next Step:**

1.  Confirm that running `git reset --hard HEAD` from a WSL terminal (while Cursor is closed) has successfully cleaned the working directory.
2.  Once the repository is confirmed to be clean in the Cursor Source Control panel, the next major task is to **begin implementing GitFlow** by creating the `develop` branch from `main`.
