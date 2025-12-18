# EventSphere - Project Report & Technical Documentation

## 1. Executive Summary
**EventSphere** is a modern, full-stack web application designed for creating, managing, and joining social activities. It fosters community engagement by allowing users to host events, follow other users, chat in real-time, and track their participation. Built with the latest technologies (**React 19, .NET 9**), it demonstrates a high standard of software engineering principles including Clean Architecture, CQRS, and reactive UI patterns.

---

## 2. Technology Stack

### Frontend (Client)
The frontend is a **Single Page Application (SPA)** built to provide a responsive and interactive user experience.
*   **Framework**: **React 19**
*   **Language**: **TypeScript** (Strict typing for robustness)
*   **Build Tool**: **Vite 6** (Fast HMR and bundling)
*   **State Management**: **MobX** (Reactive state management) & **TanStack Query** (Server state caching)
*   **UI Library**: **Material UI (MUI) v6** (Professional design system)
*   **Routing**: **React Router 7**
*   **Real-time**: **Microsoft SignalR** (Client)
*   **Form Handling**: **React Hook Form** + **Zod** (Validation)
*   **Data Visualization**: **Recharts**

### Backend (API)
The backend is a robust RESTful API built on the .NET platform, serving data to the client and handling business logic.
*   **Framework**: **.NET 9 (ASP.NET Core Web API)**
*   **Language**: **C# 13**
*   **ORM**: **Entity Framework Core 9 (EF Core)**
    *   Used for database interactions using a **Code-First** approach (C# classes define the DB schema).
    *   Leverages **LINQ** for strongly-typed queries.
*   **Architecture Pattern**: **Clean Architecture** (Domain-Centric) with **CQRS** (Command Query Responsibility Segregation) via **MediatR**.
*   **Real-time Communication**: **SignalR**
    *   Facilitates Server-to-Client push notifications for the Chat feature.
*   **Identity Management**: **ASP.NET Core Identity**
    *   Handles user registration, login, password hashing, and token generation.
*   **Dependency Injection (DI)**
    *   Utilizes the built-in .NET IoC container to manage service lifecycles (Scoped, Singleton, Transient).
*   **Middleware Pipeline**
    *   Custom Exception Middleware for global error handling.
    *   Authentication & Authorization middleware.
*   **Validation**: **FluentValidation**
    *   Decouples validation logic from Controllers/Entities.
*   **Object Mapping**: **AutoMapper**
    *   Simplifies mapping between Domain Entities and DTOs.

### Database
*   **Development**: **SQLite** (Lightweight, file-based relational database)
*   **Production Capable**: The system is designed to switch to **PostgreSQL** or **SQL Server** easily via EF Core connection string changes.

---

## 3. System Architecture

### 3.1 The Role of .NET in EventSphere
In this project, **.NET (ASP.NET Core)** acts as the robust, high-performance backend server that powers the entire application. It is not just a data fetcher; it serves as the central nervous system:
1.  **API Gateway**: It exposes RESTful endpoints (Controllers) that the React frontend consumes. Every user action (login, create event, follow user) triggers a C# method execution.
2.  **Security Enforcer**: It validates every request using **JWT Tokens** to ensure only authenticated users access protected resources. It also checks **Business Policies** (e.g., "Only the host can edit this activity").
3.  **Data Orchestrator**: Through **Entity Framework Core**, it translates C# objects into SQL commands, managing data consistency and integrity in the database completely invisibly to the frontend.
4.  **Real-Time Hub**: Using **SignalR**, it maintains open WebSocket connections to push instant updates (like chat messages) to connected clients without them needing to refresh.

### 3.2 Backend: Clean Architecture
The backend is structured into four distinct layers to enforce separation of concerns and dependency inversion.

1.  **Domain Layer** (`Domain.csproj`)
    *   **Role**: The core of the application. Contains enterprise logic and entities.
    *   **Content**: Entities like `Activity`, `AppUser`, `comment`.
    *   **Dependencies**: **None**. It is independent of frameworks and databases.

2.  **Application Layer** (`Application.csproj`)
    *   **Role**: Contains business use cases and application logic.
    *   **Content**: 
        *   **CQRS Handlers**: Separated into `Commands` (Create/Update/Delete) and `Queries` (Read).
        *   **DTOs**: Data Transfer Objects to decouple Domain entities from API responses.
        *   **Interfaces**: Defines contracts for infrastructure (e.g., `IPhotoAccessor`, `IEmailSender`) implemented in the Infrastructure layer.
        *   **MediatR**: Orchestrates the communication between the API and the Application handlers.
    *   **Dependencies**: **Domain**.

3.  **Infrastructure Layer** (`Infrastructure.csproj`)
    *   **Role**: Implements interfaces defined in the Application layer to communicate with external systems.
    *   **Content**: 
        *   **Security**: `IsHostRequirement` handler.
        *   **Photos**: Cloudinary implementation for image storage.
        *   **Email**: Resend implementation for emails.
    *   **Dependencies**: **Application**.

4.  **Persistence Layer** (`Persistence.csproj` - Merged into API/Infrastructure in this setup or separate)
    *   **Role**: Handles database access.
    *   **Content**: `DataContext` (EF Core context), Migrations, Seed Data.

5.  **API Layer** (`API.csproj`)
    *   **Role**: The entry point for HTTP requests.
    *   **Content**: Controllers, Middleware (Error handling), Dependency Injection setup (`Program.cs`).
    *   **Dependencies**: **Application**, **Infrastructure**.

### Frontend: MVVM-Like Architecture
The frontend uses **MobX Stores** which act similarly to **ViewModels** in the MVVM pattern.
*   **View**: React Components (Display data, handle user events).
*   **Store (ViewModel)**: Holds state (observable data), contains actions (methods to modify state), and computed values.
*   **Agent**: A dedicated API abstraction layer (`agent.ts`) using **Axios** to communicate with the Backend.

---

## 4. Database Design & Schema

The database relies on a relational model managed by EF Core.

### Key Entities
*   **AppUser**: Extends `IdentityUser`. Stores `DisplayName`, `Bio`, `Photos`.
*   **Activity**: Represents an event. Stores `Title`, `Date`, `Description`, `Category`, `City`, `Venue`.
*   **ActivityAttendee**: A join table representing the **Many-to-Many** relationship between Users and Activities. Includes `IsHost` flag to value-add the relationship.
*   **Comment**: Represents a chat message. Linked to `Activity` and `AppUser`.
*   **Photo**: Stores image URLs and metadata (e.g., `IsMain`). Linked to `AppUser`.
*   **UserFollowing**: A self-referencing Many-to-Many relationship on `AppUser` to handle "Followers" and "Following".

### Entity Framework Features Used
*   **Fluent API**: Configures complex relationships (e.g., Delete Behavior `Cascade`).
*   **Migrations**: Code-first approach to schema management.
*   **Projection**: Using `ProjectTo<Dto>` with AutoMapper to generate optimized SQL queries that fetch only needed columns.

---

## 5. MVC vs. Modern Stack (Analysis)

### Traditional MVC
In traditional MVC (e.g., ASP.NET MVC 5):
*   **Model**: Database Entities.
*   **View**: Razor Views (.cshtml) rendered on the Server.
*   **Controller**: Handles HTTP request, talks to DB, returns HTML.

### EventSphere Architecture (SPA + API)
*   **View (Frontend)**: React handles the presentation logic entirely in the browser. It consumes JSON data.
*   **Controller (API)**: The API Controllers (`ActivitiesController`, `AccountController`) are "Generic Controllers". They are **Thin Controllers** that do not contain business logic. They simply receive the Request, create a Command/Query object, send it to MediatR, and return the Result.
*   **Model (Backend)**: The "Model" is the Application Layer (Handlers + Logic + Domain Entities).

**Why this is better?**
*   **Decoupling**: The API can serve Mobile Apps or other clients without change.
*   **Scalability**: Frontend and Backend can be scaled independently.
*   **UX**: SPA provides a smoother, app-like experience without full page reloads.

---

## 6. Key Features Implementation

### Authentication & Security
*   **JWT (JSON Web Tokens)**: Stateless authentication. The server issues a token signed with a secret key. The client sends this token in the `Authorization` header.
*   **Policy-Based Authorization**: Custom policies (e.g., "IsActivityHost") ensure only the host can edit/delete an activity.
*   **Password Hashing**: Managed securely by ASP.NET Core Identity.

### Real-Time Chat (SignalR)
*   **Hubs**: `ChatHub.cs` manages connections.
*   **Groups**: Users join a group named after the `ActivityId`. This ensures messages are only broadcast to users correctly viewing that specific activity.
*   **Integration**: Integrated with the same JWT auth to identify users in the socket connection.

### Image Upload
*   **Cloudinary**: Images are not stored in the database (BLOBs) but in a cloud service (Cloudinary). The DB only stores the URL and Public ID.
*   **Transformation**: Images can be transformed (cropped/resized) on the fly via URL parameters.

### Notifications
*   **Implementation**: A dedicated system to alert users when:
    *   They are followed.
    *   An activity they host is joined.
*   **Polling/React Query**: The frontend creates a hook `useNotifications` to fetch and display alerts.

---

## 7. How to Run

### Prerequisities
*   .NET 9.0 SDK
*   Node.js (v18 or higher)

### Backend
1.  Navigate to `API` folder.
2.  Run `dotnet restore`
3.  Run `dotnet watch` (Starts server on `https://localhost:5001`)

### Frontend
1.  Navigate to `client` folder.
2.  Run `npm install`
3.  Run `npm run dev` (Starts client on `https://localhost:3000`)

---
---

## 8. API Endpoints Reference

The application exposes the following RESTful endpoints via the `API` layer.

### Activities (`/api/activities`)
*   `GET /` - Retrieve a paginated, filtered list of activities.
*   `GET /{id}` - Retrieve details of a specific activity.
*   `POST /` - Create a new activity.
*   `PUT /{id}` - Update an existing activity (Policy: Host only).
*   `DELETE /{id}` - Delete an activity (Policy: Host only).
*   `POST /{id}/attend` - Toggle attendance (Join/Cancel) for the current user.

### Account (`/api/account`)
*   `POST /login` - Authenticate user and return JWT + User DTO.
*   `POST /register` - Register a new user account.
*   `GET /` - Get the currently authenticated user's details (using JWT).
*   `POST /verifyEmail` - Confirm email address (if enabled).
*   `GET /resendEmailConfirmationLink` - Resend verification email.
*   `POST /forgotPassword` - Request password reset link.
*   `POST /resetPassword` - Reset password using token.

### Profiles (`/api/profiles`)
*   `GET /{username}` - Get user profile details (bio, photos, stats).
*   `PUT /` - Update current user's profile (DisplayName, Bio).
*   `GET /{username}/activities` - Get activities the user is attending/hosting.

### Photos (`/api/photos`)
*   `POST /` - Upload a new photo to Cloudinary.
*   `DELETE /{id}` - Delete a photo.
*   `POST /{id}/setMain` - Set a photo as the main profile picture.

### Follow (`/api/follow`)
*   `POST /{username}` - Toggle follow/unfollow status for a user.
*   `GET /{username}` - Get list of followers or followings for a user.

### Activities (Test) (`/api/activities/notifications-test`)
*   `GET /` - Temporary endpoint to test notification fetching logic.

---
*Generated by Antigravity AI - 2025*
