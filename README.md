# Vapor Test API

A Vapor-based Swift API with PostgreSQL and Fluent ORM, featuring CSV parsing, Google Sheets integration, and JWT authentication.

## Features

- **CSV File Upload & Parsing**: Upload CSV files and parse them dynamically based on headers
- **Google Sheets Integration**: Fetch data from Google Sheets and append new records
- **JWT Authentication**: Secure user authentication with JWT tokens
- **PostgreSQL Database**: Robust data storage with Fluent ORM
- **Docker Support**: Containerized deployment with Docker and Docker Compose
- **Health Checks**: Built-in health monitoring endpoints
- **Automated CI/CD**: GitHub Actions workflow for automated builds and deployments

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Swift 6.0+ (for local development)
- PostgreSQL (for local development)

### Using Docker (Recommended)

1. **Clone the repository**:
   ```bash
   git clone https://github.com/ArtyomV-iOS/vapor-test.git
   cd vapor-test
   ```

2. **Deploy using the automated script**:
   ```bash
   ./deploy.sh
   ```

   Or manually:
   ```bash
   # Build and start services
   docker-compose up -d
   
   # Run migrations
   docker-compose run --rm migrate
   ```

3. **Access the API**:
   - API Base URL: http://localhost:8080
   - Health Check: http://localhost:8080/health
   - Database: localhost:5432

### Local Development

1. **Install dependencies**:
   ```bash
   swift package resolve
   ```

2. **Set up PostgreSQL**:
   ```bash
   # Using Docker
   docker run --name postgres -e POSTGRES_USER=vapor_username -e POSTGRES_PASSWORD=vapor_password -e POSTGRES_DB=vapor_database -p 5432:5432 -d postgres:15-alpine
   ```

3. **Run migrations**:
   ```bash
   swift run App migrate --yes
   ```

4. **Start the server**:
   ```bash
   swift run App serve --env development
   ```

## API Endpoints

### Health Check
- `GET /health` - Application health status

### Events
- `POST /events/upload-csv` - Upload and parse CSV file
- `POST /events/upload-from-sheets` - Fetch data from Google Sheets
- `POST /events/add-to-sheets` - Add event to Google Sheets
- `GET /events` - Get all events
- `POST /events` - Create new event

### Users
- `POST /users/register` - Register new user
- `POST /users/login` - Login user (returns JWT token)
- `GET /users` - Get all users
- `POST /users` - Create new user

## Environment Variables

Create a `.env` file in the root directory:

```env
LOG_LEVEL=debug
DATABASE_HOST=localhost
DATABASE_NAME=vapor_database
DATABASE_USERNAME=vapor_username
DATABASE_PASSWORD=vapor_password
```

## Docker Commands

### Build and Run
```bash
# Build the image
docker-compose build

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

### Database Operations
```bash
# Run migrations
docker-compose run --rm migrate

# Revert migrations
docker-compose run --rm revert
```

### Development
```bash
# Run with hot reload (development)
docker-compose -f docker-compose.dev.yml up

# Access container shell
docker-compose exec app bash
```

## GitHub Actions

The repository includes automated CI/CD pipeline:

1. **Build**: Automatically builds Docker image on push/PR
2. **Test**: Runs integration tests with PostgreSQL
3. **Deploy**: Deploys to production (main/master branch only)

### Manual Deployment

```bash
# Build and push to GitHub Container Registry
docker build -t ghcr.io/artyomv-ios/vapor-test:latest .
docker push ghcr.io/artyomv-ios/vapor-test:latest
```

## Project Structure

```
Test-API/
├── Sources/App/
│   ├── Controllers/          # API controllers
│   ├── Models/              # Database models
│   ├── DTOs/                # Data transfer objects
│   ├── Migrations/          # Database migrations
│   └── configure.swift      # App configuration
├── Resources/Views/         # Leaf templates
├── Public/                  # Static files
├── Tests/                   # Unit tests
├── Dockerfile              # Docker configuration
├── docker-compose.yml      # Docker Compose setup
├── deploy.sh               # Deployment script
└── .github/workflows/      # CI/CD workflows
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For issues and questions:
- Create an issue on GitHub
- Check the documentation
- Review the logs: `docker-compose logs -f` 