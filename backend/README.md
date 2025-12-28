# Egypt Electronics Backend API

FastAPI backend for the Egypt Electronics price comparison Flutter app.

## Features

- **Product Management**: CRUD operations for electronics products
- **Multi-store Scraping**: Automated scraping from multiple electronics stores
- **Flutter Compatible**: API endpoints optimized for Flutter mobile app
- **CORS Support**: Configured for Flutter web development
- **Real-time Status**: Live scraping status updates

## API Endpoints

### Products
- `GET /api/products` - Get all products
- `POST /api/products/add-sample` - Add sample products for testing

### Scraping
- `POST /api/scrape` - Start scraping all stores
- `GET /api/scrape/status` - Get current scraping status

### Stats
- `GET /api/stats` - Get product statistics

### Root
- `GET /` - API health check

## Supported Stores

- **Microohm**: Electronics components and modules
- **ElectroHub**: Development boards and tools
- **Ekostra**: Electronic components
- **RAM**: Test equipment and tools

## Installation

1. Create virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install fastapi uvicorn pydantic
```

3. Run the server:
```bash
python main_fastapi.py
```

## Flutter Integration

The API is specifically configured for Flutter apps:

- **CORS**: Allows Flutter web app (http://127.0.0.1:55109)
- **Data Format**: JSON responses compatible with Flutter models
- **Error Handling**: Proper HTTP status codes for Flutter HTTP client
- **Null Safety**: Optional fields handled properly for Dart null safety

## Sample Data

Use the sample data endpoint to quickly populate the database for testing:
```bash
curl -X POST http://127.0.0.1:8000/api/products/add-sample
```

## Configuration

- **Host**: 127.0.0.1
- **Port**: 8000
- **Auto-reload**: Enabled for development

## Data Model

```python
Product {
    id: int
    name: str
    price: float
    image: str (optional)
    brand: str
    category: str
    store: str
    availability: str
    rating: float
}
```

## Flutter App Usage

```dart
// Example Flutter HTTP call
final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/products'));
if (response.statusCode == 200) {
    final List<Product> products = productFromJson(response.body);
}
```

## Development

The server runs with auto-reload enabled. Changes to the Python files will automatically restart the server.

## Testing

1. Start the backend server
2. Use the Flutter app or curl to test endpoints
3. Check the console for scraping progress

## Troubleshooting

- **CORS Issues**: Ensure Flutter app URL is in allowed origins
- **Scraping Failures**: Check individual scraper modules in `/scrapers` directory
- **Empty Products**: Use sample data endpoint for initial testing
