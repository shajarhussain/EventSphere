# Viva Presentation Script: 'Reactivities' Database Architecture

## Opening Line
"For the backend data persistence, I used **SQLite** for development (which is lightweight and file-based) but designed the system using **Entity Framework Core** Code-First approach. This means the database schema is generated programmatically from my C# models, making it compatible with production databases like SQL Server or PostgreSQL."

## 1. Authentication & Security (The `AspNet` Tables)
"First, you'll see a set of tables starting with `AspNet...` (like `AspNetUsers`, `AspNetRoles`).
*   **What to say:** 'I implemented industry-standard security using **ASP.NET Core Identity**. Instead of building a login system from scratch (which is insecure), I used these framework-standard tables to handle user registration, secure password hashing, and role management safely.'"

## 2. Core Functionality (The `Activities` Table)
"The heart of the application is the **`Activities`** table.
*   **What to say:** 'This stores all the events. It holds details like Title, Date, Description, and Geo-location data (Latitude/Longitude) for maps. It also supports both physical events and virtual ones, with columns for Zoom meeting URLs and IDs.'"

## 3. Relationships (The Logic)
"The real complexity lies in how these tables connect. I have implemented several advanced relationships:"

### A. Many-to-Many Relationship (`ActivityAttendees`)
*   **Point to:** The `ActivityAttendees` table.
*   **What to say:** "'This is a **Join Table** connecting Users and Activities. It allows a 'Many-to-Many' relationship.
    *   One User can attend *Many* Activities.
    *   One Activity can have *Many* Attendees.
    *   This table also tracks extra data, like who is the **Host** (`IsHost` column) of the activity.'"

### B. Self-Referencing Relationship (`UserFollowings`)
*   **Point to:** The `UserFollowings` table.
*   **What to say:** "'This enables the social network aspect. It is a **Self-Referencing Many-to-Many relationship**. It links the `AspNetUsers` table to itself, allowing users to follow each other (creating Observer/Target relationships).'"

### C. One-to-Many Relationships (`Comments`, `Photos`, `Notifications`)
*   **Point to:** `Comments` and `Photos`.
*   **What to say:** "I also have One-to-Many relationships:
    *   **Comments:** One Activity has many Comments (for the chat feature).
    *   **Photos:** One User has many Photos.
    *   **Notifications:** Used to alert users of updates.'"

## Summary for Q&A
**If asked "Why code-first?"**
*   "It allows me to version control my database schema using **Migrations** (the `_EFMigrationsHistory` table tracks this), making updates and team collaboration much easier."

**If asked "Why SQLite?"**
*   "It's zero-configuration and perfect for development demos. The code abstraction allows me to switch to SQL Server for deployment by changing just one line of configuration."
