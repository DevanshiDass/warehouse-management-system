# Warehouse Management System (with GIS & Profit Tracking)

This project implements a **geo-aware logistics backend** using **MySQL**, enabling warehouse location management, customer proximity matching, shipment planning, and financial profit analysis.

## 🚀 Key Features

| Feature | Description |
|--------|-------------|
| Warehouse Geo-Location | Warehouses stored as `POINT` with SRID=4326 for real-world coordinates. |
| Auto Distance Mapping | Distances between warehouses auto-calculated & stored. |
| Nearest Warehouse Routing | Customers are automatically assigned shipments from the nearest warehouse. |
| Shipment Tracking | Support for pending → shipped → delivered lifecycle. |
| Financial Accounting | Revenue, cost, and profit recorded for each shipment. |
| Profit Trends | Generate monthly profit analytics and top-performing warehouses. |

---

## 🗺️ Geospatial Capabilities
- Uses `ST_Distance_Sphere()` to compute real-world distance between coordinates.
- Automatically calculates distances when new warehouses are added (via trigger).

---

---

## 📊 Example Queries

- **Nearest Warehouse to Customer**
- **Top 3 Most Profitable Warehouses**
- **Monthly Profit Trend**

---

## 🛠️ Requirements

| Tool | Version |
|------|---------|
| MySQL | 8.0+ (with Spatial support) |

---

## 🏁 How to Run

```bash
mysql -u root -p < logistics_system.sql


## 📦 Database Schema Overview

