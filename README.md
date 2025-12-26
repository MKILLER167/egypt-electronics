# Egypt Electronics Price Comparison

A web application for comparing electronics prices across multiple Egyptian stores.

## Features

- **Real-time Search**: Instant product search with dropdown suggestions
- **Price Comparison**: Compare prices from multiple stores
- **Filtering**: Filter by brand, store, and price range
- **Product Details**: Detailed product information with similar products
- **Keyboard Navigation**: Full keyboard support (Arrow keys, Enter, Escape)
- **Responsive Design**: Works on desktop and mobile devices

## Tech Stack

### Frontend
- React.js
- Tailwind CSS
- Lucide React Icons

### Backend
- FastAPI (Python)
- Web Scraping (BeautifulSoup, Requests)
- CORS support

## Installation

### Backend Setup
```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python -m uvicorn main_fastapi:app --host 127.0.0.1 --port 8000
```

### Frontend Setup
```bash
cd frontend
npm install
npm start
```

## Usage

1. Start the backend server (port 8000)
2. Start the frontend development server (port 3000)
3. Open http://localhost:3000 in your browser
4. Use the search bar to find products
5. Click "Update" to scrape latest prices
6. Use filters to narrow down results

## API Endpoints

- `GET /api/products` - Get all products
- `POST /api/scrape` - Start web scraping
- `POST /api/products/add-sample` - Add sample data

## Keyboard Shortcuts

- **Arrow Up/Down**: Navigate search suggestions
- **Enter**: Select product or search
- **Escape**: Close dropdown

## Stores Supported

- Microohm
- ElectroHub  
- Ekostra
- RAM Electronics

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License
