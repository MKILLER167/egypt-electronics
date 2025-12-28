# GitHub Pages Deployment Guide

## Egypt Electronics Flutter App

### Prerequisites
- GitHub account
- Repository named `egypt_electronics`
- Flutter web build completed

### Deployment Steps

1. **Create GitHub Repository**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin https://github.com/yourusername/egypt_electronics.git
   git push -u origin main
   ```

2. **Enable GitHub Pages**
   - Go to repository settings
   - Scroll to "Pages" section
   - Source: Deploy from a branch
   - Branch: main
   - Folder: /root
   - Save

3. **Build for Production**
   ```bash
   flutter build web --base-href "/egypt_electronics/"
   ```

4. **Deploy Files**
   - Copy contents of `build/web/` to repository root
   - Commit and push changes

### Access URL
https://yourusername.github.io/egypt_electronics/

### Backend API
The app expects API at: `http://127.0.0.1:8000`

For production, update the API URL in `lib/main.dart` to your deployed backend.

### Features
- Dark theme with orange accents
- Product catalog with search/filter
- Favorites and compare functionality
- Responsive design
- Analytics dashboard
