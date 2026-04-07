# Inventory Management App

A Flutter-based inventory management application with Firebase integration for real-time CRUD operations on inventory items.

## Features

### Core Features
- **Real-time Firebase Integration**: Uses Cloud Firestore for seamless data synchronization
- **Complete CRUD Operations**: Create, Read, Update, and Delete inventory items
- **Auto-incrementing Item Numbers**: Automatically generates the next sequential item number
- **Typed Data Model**: 
  - Item # (double)
  - Item Name (string)
  - Item Stock (double)
  - Item Type (string)

### Enhanced Features

#### 1. **Search & Filter Functionality**
Search and filter items in real-time by:
- **Item Name**: Search for items by their name
- **Item Type**: Filter items by category/type
- **Item ID Number**: Search by the item number
- **Real-time Updates**: Search results update instantly as you type
- **Clear Button**: Quickly clear search with a single tap

**Use Case**: Quickly locate specific items in your inventory without scrolling through the entire list.

#### 2. **Low Stock Alerts** ⚠️
Proactive inventory management with visual alerts:
- **Automatic Detection**: Items with stock below 10 units are automatically flagged
- **Visual Indicators**: 
  - Warning icon (⚠️) appears next to low stock items
  - Items are highlighted with an orange tint
  - Text color changes to indicate urgency
- **Low Stock Filter**: Toggle button to view only low-stock items
- **Tooltip Information**: Hover over the warning icon to see "Low Stock Alert" message

**Use Case**: Never run out of stock. Quickly identify items that need restocking and manage inventory levels proactively.

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Firebase project with Firestore enabled
- iOS deployment target: 11.0 or higher
- Android minimum SDK version: 21 or higher

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd inventory_management_app
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure Firebase
- Follow the [Firebase setup guide](https://firebase.flutter.dev/docs/overview/)
- Download your `GoogleService-Info.plist` (iOS) or `google-services.json` (Android)
- Place them in the appropriate directories

4. Run the app
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # Home page and UI
├── models/
│   └── item.dart            # Item data model
├── services/
│   └── firebase_service.dart # Firebase operations and typed streams
└── firebase_options.dart    # Firebase configuration
```

## Architecture

### Layered Architecture
- **UI Layer**: Flutter widgets with `StreamBuilder` for real-time updates
- **Service Layer**: `FirebaseService` singleton providing typed streams
- **Data Layer**: Cloud Firestore with type-safe data models

### Key Design Patterns
- **Singleton Pattern**: `FirebaseService` for consistent service instance
- **Reactive Streams**: Real-time data using Firestore snapshots
- **MVC Pattern**: Separation of models, views, and service logic

## Stream Operations

The Firebase service provides the following typed streams:

- `getItemsStream()` → `Stream<List<Item>>`
- `getItemStream(id)` → `Stream<Item?>`
- `getItemsByTypeStream(type)` → `Stream<List<Item>>`
- `getLowStockItemsStream(threshold)` → `Stream<List<Item>>`
- `searchItemsStream(query)` → `Stream<List<Item>>`
- `getItemsSortedByStock()` → `Stream<List<Item>>`

## Dependencies

- `firebase_core`: Firebase initialization
- `cloud_firestore`: Cloud database access
- `flutter`: UI framework

## License

This project is licensed under the MIT License.

## Support

For issues or feature requests, please open an issue on the repository.

---

**Last Updated**: April 2026
