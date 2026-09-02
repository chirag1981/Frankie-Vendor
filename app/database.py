"""
Database operations using SQLite for local persistent storage.
Supports Shop Settings, Catalog Menu Items, and Invoice records.
"""

from datetime import datetime
import os
import sqlite3
from typing import Any, Dict, List, Optional, Tuple

DB_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "vendor_invoice.db")


def get_connection() -> sqlite3.Connection:
    """Returns a SQLite connection with Row factory enabled."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def init_db() -> None:
    """Initializes the database schema and default shop settings and catalog items."""
    with get_connection() as conn:
        cursor = conn.cursor()

        # 1. Shop Settings Table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS shop_settings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                shop_name TEXT NOT NULL,
                phone TEXT DEFAULT '',
                address TEXT DEFAULT '',
                upi_id TEXT DEFAULT '',
                currency TEXT DEFAULT '₹',
                tax_percent REAL DEFAULT 0.0,
                footer_note TEXT DEFAULT 'Thank you for your visit!',
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # 2. Catalog / Menu Items Table (for fast tap-to-add billing)
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS catalog_items (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL UNIQUE,
                price REAL NOT NULL,
                category TEXT DEFAULT 'General',
                is_active INTEGER DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # 3. Invoices Table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS invoices (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                invoice_number TEXT NOT NULL UNIQUE,
                customer_name TEXT DEFAULT '',
                customer_phone TEXT DEFAULT '',
                subtotal REAL NOT NULL,
                discount REAL DEFAULT 0.0,
                tax REAL DEFAULT 0.0,
                grand_total REAL NOT NULL,
                payment_mode TEXT DEFAULT 'Cash',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # 4. Invoice Items Table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS invoice_items (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                invoice_id INTEGER NOT NULL,
                item_name TEXT NOT NULL,
                quantity REAL NOT NULL,
                unit_price REAL NOT NULL,
                line_total REAL NOT NULL,
                FOREIGN KEY(invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
            )
        """)

        # Insert default shop settings if empty
        cursor.execute("SELECT COUNT(*) as cnt FROM shop_settings")
        if cursor.fetchone()["cnt"] == 0:
            cursor.execute("""
                INSERT INTO shop_settings (shop_name, phone, address, upi_id, currency, tax_percent, footer_note)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                "FRANKIE CORNER",
                "9876543210",
                "Food Street, Market Road",
                "shopkeeper@upi",
                "₹",
                0.0,
                "Fresh & Delicious! Visit Again!"
            ))

        # Insert default sample menu items if empty
        cursor.execute("SELECT COUNT(*) as cnt FROM catalog_items")
        if cursor.fetchone()["cnt"] == 0:
            sample_items = [
                ("VEG FRANKIE", 50.0, "Frankie"),
                ("CHEESE VEG FRANKIE", 70.0, "Frankie"),
                ("PANEER FRANKIE", 80.0, "Frankie"),
                ("CHEESE PANEER FRANKIE", 100.0, "Frankie"),
                ("SCHEZWAN NOODLE FRANKIE", 60.0, "Frankie"),
                ("PERI PERI FRIES", 70.0, "Snacks"),
                ("COLD COFFEE", 40.0, "Beverages"),
                ("MINERAL WATER (500ML)", 10.0, "Beverages"),
            ]
            cursor.executemany(
                "INSERT INTO catalog_items (name, price, category) VALUES (?, ?, ?)",
                sample_items
            )

        conn.commit()


# --- Shop Settings Queries ---

def get_shop_settings() -> Dict[str, Any]:
    """Fetch current shop profile settings."""
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM shop_settings ORDER BY id ASC LIMIT 1")
        row = cursor.fetchone()
        if row:
            return dict(row)
        return {
            "shop_name": "MY SHOP",
            "phone": "",
            "address": "",
            "upi_id": "",
            "currency": "₹",
            "tax_percent": 0.0,
            "footer_note": "Thank you for your visit!"
        }


def update_shop_settings(
    shop_name: str,
    phone: str = "",
    address: str = "",
    upi_id: str = "",
    currency: str = "₹",
    tax_percent: float = 0.0,
    footer_note: str = ""
) -> None:
    """Update shop profile settings."""
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM shop_settings ORDER BY id ASC LIMIT 1")
        row = cursor.fetchone()
        if row:
            cursor.execute("""
                UPDATE shop_settings
                SET shop_name = ?, phone = ?, address = ?, upi_id = ?, currency = ?,
                    tax_percent = ?, footer_note = ?, updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
            """, (shop_name.strip().upper(), phone.strip(), address.strip(), upi_id.strip(), currency.strip(), tax_percent, footer_note.strip(), row["id"]))
        else:
            cursor.execute("""
                INSERT INTO shop_settings (shop_name, phone, address, upi_id, currency, tax_percent, footer_note)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (shop_name.strip().upper(), phone.strip(), address.strip(), upi_id.strip(), currency.strip(), tax_percent, footer_note.strip()))
        conn.commit()


# --- Catalog Menu Items Queries ---

def get_catalog_items(active_only: bool = True) -> List[Dict[str, Any]]:
    """Retrieve list of catalog menu items."""
    with get_connection() as conn:
        cursor = conn.cursor()
        if active_only:
            cursor.execute("SELECT * FROM catalog_items WHERE is_active = 1 ORDER BY category ASC, name ASC")
        else:
            cursor.execute("SELECT * FROM catalog_items ORDER BY category ASC, name ASC")
        return [dict(row) for row in cursor.fetchall()]


def add_catalog_item(name: str, price: float, category: str = "General") -> int:
    """Add a new item to catalog."""
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO catalog_items (name, price, category) VALUES (?, ?, ?)",
            (name.strip().upper(), float(price), category.strip().upper() or "GENERAL")
        )
        conn.commit()
        return cursor.lastrowid or 0


def update_catalog_item(item_id: int, name: str, price: float, category: str = "General") -> None:
    """Update existing item."""
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "UPDATE catalog_items SET name = ?, price = ?, category = ? WHERE id = ?",
            (name.strip().upper(), float(price), category.strip().upper() or "GENERAL", item_id)
        )
        conn.commit()


def delete_catalog_item(item_id: int) -> None:
    """Soft-delete or remove item."""
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("DELETE FROM catalog_items WHERE id = ?", (item_id,))
        conn.commit()


# --- Invoice Operations ---

def get_next_invoice_number() -> str:
    """Generate sequential invoice number (e.g. INV-1001)."""
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM invoices ORDER BY id DESC LIMIT 1")
        row = cursor.fetchone()
        last_id = row["id"] if row else 0
        return f"INV-{1001 + last_id}"


def create_invoice(
    invoice_number: str,
    customer_name: str,
    customer_phone: str,
    items: List[Dict[str, Any]],
    discount: float = 0.0,
    tax: float = 0.0,
    payment_mode: str = "Cash"
) -> int:
    """
    Creates an invoice and child line items in an atomic transaction.
    Returns the created invoice ID.
    """
    subtotal = sum(float(item["quantity"]) * float(item["unit_price"]) for item in items)
    grand_total = max(0.0, subtotal - discount + tax)

    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO invoices (
                invoice_number, customer_name, customer_phone, subtotal, discount, tax, grand_total, payment_mode
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            invoice_number.strip().upper(),
            customer_name.strip().upper(),
            customer_phone.strip(),
            round(subtotal, 2),
            round(discount, 2),
            round(tax, 2),
            round(grand_total, 2),
            payment_mode
        ))
        invoice_id = cursor.lastrowid or 0

        for item in items:
            qty = float(item["quantity"])
            price = float(item["unit_price"])
            line_total = round(qty * price, 2)
            cursor.execute("""
                INSERT INTO invoice_items (invoice_id, item_name, quantity, unit_price, line_total)
                VALUES (?, ?, ?, ?, ?)
            """, (
                invoice_id,
                item["item_name"].strip().upper(),
                qty,
                price,
                line_total
            ))

        conn.commit()
        return invoice_id


def get_invoices(search_query: str = "", limit: int = 50, offset: int = 0) -> List[Dict[str, Any]]:
    """Retrieve list of invoices with optional search by invoice number, customer name, or phone."""
    with get_connection() as conn:
        cursor = conn.cursor()
        if search_query:
            query_param = f"%{search_query.strip()}%"
            cursor.execute("""
                SELECT * FROM invoices
                WHERE invoice_number LIKE ? OR customer_name LIKE ? OR customer_phone LIKE ?
                ORDER BY id DESC LIMIT ? OFFSET ?
            """, (query_param, query_param, query_param, limit, offset))
        else:
            cursor.execute("SELECT * FROM invoices ORDER BY id DESC LIMIT ? OFFSET ?", (limit, offset))

        invoices = []
        for row in cursor.fetchall():
            inv = dict(row)
            # Fetch line items count
            cursor.execute("SELECT COUNT(*) as item_count FROM invoice_items WHERE invoice_id = ?", (inv["id"],))
            inv["item_count"] = cursor.fetchone()["item_count"]
            invoices.append(inv)
        return invoices


def get_invoice_by_id(invoice_id: int) -> Optional[Dict[str, Any]]:
    """Retrieve full invoice details along with its line items."""
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM invoices WHERE id = ?", (invoice_id,))
        row = cursor.fetchone()
        if not row:
            return None

        invoice_data = dict(row)
        cursor.execute("SELECT * FROM invoice_items WHERE invoice_id = ? ORDER BY id ASC", (invoice_id,))
        invoice_data["items"] = [dict(item) for item in cursor.fetchall()]
        return invoice_data


def delete_invoice(invoice_id: int) -> None:
    """Delete an invoice and its items."""
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("DELETE FROM invoices WHERE id = ?", (invoice_id,))
        conn.commit()


def get_sales_summary() -> Dict[str, Any]:
    """Calculates summary statistics: Total revenue, today's revenue, total count."""
    with get_connection() as conn:
        cursor = conn.cursor()
        # All time
        cursor.execute("SELECT COUNT(*) as total_bills, COALESCE(SUM(grand_total), 0) as total_sales FROM invoices")
        all_time = cursor.fetchone()

        # Today
        cursor.execute("""
            SELECT COUNT(*) as today_bills, COALESCE(SUM(grand_total), 0) as today_sales
            FROM invoices
            WHERE DATE(created_at) = DATE('now', 'localtime')
        """)
        today = cursor.fetchone()

        return {
            "total_bills": all_time["total_bills"] if all_time else 0,
            "total_sales": all_time["total_sales"] if all_time else 0.0,
            "today_bills": today["today_bills"] if today else 0,
            "today_sales": today["today_sales"] if today else 0.0,
        }
