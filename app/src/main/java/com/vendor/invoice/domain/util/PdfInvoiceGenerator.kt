package com.vendor.invoice.domain.util

import android.content.Context
import android.content.Intent
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import android.net.Uri
import android.os.Environment
import androidx.core.content.FileProvider
import com.vendor.invoice.data.local.entity.InvoiceEntity
import com.vendor.invoice.data.local.entity.InvoiceItemEntity
import com.vendor.invoice.data.local.entity.ShopSettingsEntity
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object PdfInvoiceGenerator {

    fun generatePdf(
        context: Context,
        shopSettings: ShopSettingsEntity,
        invoice: InvoiceEntity,
        items: List<InvoiceItemEntity>
    ): File? {
        val pageWidth = 420 // A5 width in points (approx 148mm)
        val pageHeight = 595 // A5 height in points (approx 210mm)

        val document = PdfDocument()
        val pageInfo = PdfDocument.PageInfo.Builder(pageWidth, pageHeight, 1).create()
        val page = document.startPage(pageInfo)
        val canvas: Canvas = page.canvas

        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val currency = if (shopSettings.currency == "₹") "Rs." else shopSettings.currency

        // 1. Top Brand Banner
        paint.color = Color.rgb(33, 150, 243) // Material Blue
        canvas.drawRect(0f, 0f, pageWidth.toFloat(), 12f, paint)

        // 2. Shop Header
        paint.color = Color.rgb(25, 30, 45)
        paint.textSize = 18f
        paint.typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        paint.textAlign = Paint.Align.CENTER
        val shopName = shopSettings.shopName.uppercase().ifEmpty { "VENDOR INVOICE" }
        canvas.drawText(shopName, pageWidth / 2f, 35f, paint)

        paint.textSize = 9f
        paint.typeface = Typeface.create(Typeface.DEFAULT, Typeface.NORMAL)
        paint.color = Color.rgb(90, 90, 90)
        var currentY = 48f
        if (shopSettings.address.isNotBlank()) {
            canvas.drawText(shopSettings.address, pageWidth / 2f, currentY, paint)
            currentY += 12f
        }
        if (shopSettings.phone.isNotBlank()) {
            canvas.drawText("Phone: ${shopSettings.phone}", pageWidth / 2f, currentY, paint)
            currentY += 12f
        }

        currentY += 4f
        paint.color = Color.rgb(220, 220, 220)
        paint.strokeWidth = 1f
        canvas.drawLine(20f, currentY, pageWidth - 20f, currentY, paint)
        currentY += 16f

        // 3. Invoice Metadata
        paint.textSize = 10f
        paint.color = Color.rgb(40, 40, 40)
        paint.typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        paint.textAlign = Paint.Align.LEFT
        canvas.drawText("Invoice: ${invoice.invoiceNumber}", 20f, currentY, paint)

        paint.textAlign = Paint.Align.RIGHT
        canvas.drawText("Date: ${invoice.createdAt.take(16)}", pageWidth - 20f, currentY, paint)
        currentY += 14f

        if (invoice.customerName.isNotBlank() || invoice.customerPhone.isNotBlank()) {
            paint.textAlign = Paint.Align.LEFT
            paint.typeface = Typeface.create(Typeface.DEFAULT, Typeface.NORMAL)
            val custText = buildString {
                append("Customer: ")
                append(invoice.customerName.ifEmpty { "Walk-in Customer" })
                if (invoice.customerPhone.isNotBlank()) {
                    append(" (${invoice.customerPhone})")
                }
            }
            canvas.drawText(custText, 20f, currentY, paint)
            currentY += 14f
        }

        currentY += 6f

        // 4. Table Header
        val colNo = 20f
        val colItem = 45f
        val colQty = 250f
        val colRate = 310f
        val colTotal = pageWidth - 20f

        paint.color = Color.rgb(240, 244, 248)
        canvas.drawRect(20f, currentY - 10f, pageWidth - 20f, currentY + 10f, paint)

        paint.color = Color.rgb(30, 41, 59)
        paint.textSize = 9f
        paint.typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        paint.textAlign = Paint.Align.CENTER
        canvas.drawText("#", colNo + 8f, currentY + 3f, paint)
        paint.textAlign = Paint.Align.LEFT
        canvas.drawText("ITEM DESCRIPTION", colItem, currentY + 3f, paint)
        paint.textAlign = Paint.Align.CENTER
        canvas.drawText("QTY", colQty + 15f, currentY + 3f, paint)
        paint.textAlign = Paint.Align.RIGHT
        canvas.drawText("RATE", colRate + 15f, currentY + 3f, paint)
        canvas.drawText("TOTAL", colTotal, currentY + 3f, paint)

        currentY += 16f

        // 5. Line Items
        paint.typeface = Typeface.create(Typeface.DEFAULT, Typeface.NORMAL)
        items.forEachIndexed { index, item ->
            val fillZebra = (index % 2 == 0)
            if (fillZebra) {
                paint.color = Color.rgb(248, 250, 252)
                canvas.drawRect(20f, currentY - 8f, pageWidth - 20f, currentY + 8f, paint)
            }

            paint.color = Color.rgb(51, 65, 85)
            paint.textAlign = Paint.Align.CENTER
            canvas.drawText((index + 1).toString(), colNo + 8f, currentY + 3f, paint)

            paint.textAlign = Paint.Align.LEFT
            val itemName = if (item.itemName.length > 28) item.itemName.take(25) + "..." else item.itemName
            canvas.drawText(itemName, colItem, currentY + 3f, paint)

            paint.textAlign = Paint.Align.CENTER
            canvas.drawText(CurrencyUtils.formatQty(item.quantity), colQty + 15f, currentY + 3f, paint)

            paint.textAlign = Paint.Align.RIGHT
            canvas.drawText(String.format(Locale.US, "%.2f", item.unitPrice), colRate + 15f, currentY + 3f, paint)
            canvas.drawText(String.format(Locale.US, "%.2f", item.lineTotal), colTotal, currentY + 3f, paint)

            currentY += 16f
        }

        paint.color = Color.rgb(203, 213, 225)
        canvas.drawLine(20f, currentY, pageWidth - 20f, currentY, paint)
        currentY += 16f

        // 6. Totals Section
        paint.textSize = 10f
        paint.textAlign = Paint.Align.RIGHT

        paint.color = Color.rgb(71, 85, 105)
        canvas.drawText("Subtotal:", 310f, currentY, paint)
        canvas.drawText("$currency ${String.format(Locale.US, "%.2f", invoice.subtotal)}", colTotal, currentY, paint)
        currentY += 14f

        if (invoice.discount > 0) {
            canvas.drawText("Discount:", 310f, currentY, paint)
            canvas.drawText("-$currency ${String.format(Locale.US, "%.2f", invoice.discount)}", colTotal, currentY, paint)
            currentY += 14f
        }

        if (invoice.tax > 0) {
            canvas.drawText("Tax/GST:", 310f, currentY, paint)
            canvas.drawText("+$currency ${String.format(Locale.US, "%.2f", invoice.tax)}", colTotal, currentY, paint)
            currentY += 14f
        }

        currentY += 4f
        paint.typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        paint.color = Color.rgb(16, 185, 129) // Emerald Green
        paint.textSize = 12f
        paint.textAlign = Paint.Align.LEFT
        canvas.drawText("Paid via: ${invoice.paymentMode}", 20f, currentY, paint)

        paint.textAlign = Paint.Align.RIGHT
        canvas.drawText("Grand Total:", 310f, currentY, paint)
        canvas.drawText("$currency ${String.format(Locale.US, "%.2f", invoice.grandTotal)}", colTotal, currentY, paint)

        // 7. Footer
        paint.color = Color.rgb(148, 163, 184)
        paint.textSize = 8f
        paint.typeface = Typeface.create(Typeface.DEFAULT, Typeface.ITALIC)
        paint.textAlign = Paint.Align.CENTER
        canvas.drawText("Powered by Quick Vendor Invoice", pageWidth / 2f, pageHeight - 20f, paint)

        document.finishPage(page)

        // Save PDF file
        val outputDir = getOutputDir(context)
        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
        val fileName = "Invoice_${invoice.invoiceNumber}_$timeStamp.pdf"
        val pdfFile = File(outputDir, fileName)

        return try {
            val fos = FileOutputStream(pdfFile)
            document.writeTo(fos)
            document.close()
            fos.close()
            pdfFile
        } catch (e: Exception) {
            e.printStackTrace()
            document.close()
            null
        }
    }

    private fun getOutputDir(context: Context): File {
        val dir = File(
            context.getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS),
            "VendorInvoices"
        )
        if (!dir.exists()) {
            dir.mkdirs()
        }
        return dir
    }

    fun openOrSharePdf(context: Context, file: File) {
        try {
            val uri: Uri = FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                file
            )
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/pdf")
                flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(Intent.createChooser(intent, "Open Invoice PDF"))
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
