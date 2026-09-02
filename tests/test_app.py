"""
Automated unit and integration tests for the Shop Vendor Invoice app.
"""

import os
import sys
import unittest

# Ensure app package is importable
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import database, pdf_service, utils


class TestVendorInvoiceApp(unittest.TestCase):

    def setUp(self):
        # Initialize schema
        database.init_db()

    def test_shop_settings(self):
        # Test update shop settings
        database.update_shop_settings(
            shop_name="TEST FRANKIE HUB",
            phone="9988776655",
            address="Near College Cross",
            upi_id="test@upi",
            currency="₹",
            footer_note="Visit us again!"
        )
        settings = database.get_shop_settings()
        self.assertEqual(settings["shop_name"], "TEST FRANKIE HUB")
        self.assertEqual(settings["phone"], "9988776655")
        self.assertEqual(settings["upi_id"], "test@upi")

    def test_catalog_crud(self):
        # Add item
        item_id = database.add_catalog_item(name="TEST SPECIAL FRANKIE", price=95.0, category="FRANKIE")
        self.assertTrue(item_id > 0)

        # Retrieve items
        items = database.get_catalog_items(active_only=True)
        found = any(it["name"] == "TEST SPECIAL FRANKIE" and it["price"] == 95.0 for it in items)
        self.assertTrue(found)

        # Update item
        database.update_catalog_item(item_id, name="TEST SPECIAL FRANKIE", price=105.0, category="SPECIAL")
        items_after = database.get_catalog_items(active_only=True)
        updated_it = next(it for it in items_after if it["id"] == item_id)
        self.assertEqual(updated_it["price"], 105.0)
        self.assertEqual(updated_it["category"], "SPECIAL")

        # Delete item
        database.delete_catalog_item(item_id)
        items_after_del = database.get_catalog_items(active_only=True)
        self.assertFalse(any(it["id"] == item_id for it in items_after_del))

    def test_invoice_creation_and_pdf(self):
        inv_no = database.get_next_invoice_number()
        items = [
            {"item_name": "CHEESE FRANKIE", "quantity": 2.0, "unit_price": 70.0, "line_total": 140.0},
            {"item_name": "COLD COFFEE", "quantity": 1.0, "unit_price": 40.0, "line_total": 40.0}
        ]
        inv_id = database.create_invoice(
            invoice_number=inv_no,
            customer_name="ROHIT SHARMA",
            customer_phone="9876501234",
            items=items,
            discount=10.0,
            tax=0.0,
            payment_mode="UPI"
        )
        self.assertTrue(inv_id > 0)

        # Retrieve full invoice
        full_inv = database.get_invoice_by_id(inv_id)
        self.assertIsNotNone(full_inv)
        self.assertEqual(full_inv["customer_name"], "ROHIT SHARMA")
        self.assertEqual(full_inv["subtotal"], 180.0)
        self.assertEqual(full_inv["discount"], 10.0)
        self.assertEqual(full_inv["grand_total"], 170.0)
        self.assertEqual(len(full_inv["items"]), 2)

        # Test WhatsApp message formatting
        shop = database.get_shop_settings()
        wa_text = utils.generate_whatsapp_bill_text(shop, full_inv, full_inv["items"])
        self.assertIn("CHEESE FRANKIE", wa_text)
        self.assertIn("170.00", wa_text)
        self.assertIn("ROHIT SHARMA", wa_text)

        wa_url = utils.get_whatsapp_share_url(full_inv["customer_phone"], wa_text)
        self.assertIn("wa.me/919876501234", wa_url)

        # Test PDF Generation
        pdf_path = pdf_service.generate_pdf_invoice(shop, full_inv, full_inv["items"])
        self.assertTrue(os.path.exists(pdf_path))
        self.assertTrue(os.path.getsize(pdf_path) > 500)

        # Summary stats check
        stats = database.get_sales_summary()
        self.assertTrue(stats["total_bills"] >= 1)
        self.assertTrue(stats["total_sales"] >= 170.0)


if __name__ == "__main__":
    unittest.main()
