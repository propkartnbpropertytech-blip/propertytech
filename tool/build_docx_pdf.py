# -*- coding: utf-8 -*-
"""
PropKart v2.1.1 - SRS Document Generator (.DOCX & .PDF)
Converts the full engineering & UI/UX specification into high-fidelity Word and PDF documents.
"""

import os
import sys
from datetime import datetime

# ── Third-Party Libraries ────────────────────────────────────────────────────
import docx
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import parse_xml, OxmlElement
from docx.oxml.ns import nsdecls, qn

from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, Image, KeepTogether, HRFlowable
)
from reportlab.pdfgen import canvas

# ── Paths ────────────────────────────────────────────────────────────────────
PROJECT_ROOT = r"c:\NB\propkart"
DOCS_DIR = os.path.join(PROJECT_ROOT, "docs")
ASSETS_DIR = os.path.join(PROJECT_ROOT, "assets", "branding")
LOCKUP_LOGO = os.path.join(ASSETS_DIR, "app_icon_lockup.png")
ICON_LOGO = os.path.join(ASSETS_DIR, "app_icon.png")

DOCX_OUTPUT = os.path.join(DOCS_DIR, "PropKart_v2.1.1_SRS_UIUX_Specification.docx")
PDF_OUTPUT = os.path.join(DOCS_DIR, "PropKart_v2.1.1_SRS_UIUX_Specification.pdf")

# ── Palette Constants ────────────────────────────────────────────────────────
HEX_TEAL = "159B73"
HEX_TERRACOTTA = "C15D4A"
HEX_DARK_BG = "0F172A"
HEX_TEXT_NAVY = "14213D"
HEX_TEXT_MUTED = "64748B"
HEX_BORDER = "E8ECF2"
HEX_BG_LIGHT = "F8FAFC"
HEX_MINT_TINT = "E8F5F1"
HEX_WHATSAPP = "25D366"

COLOR_TEAL = colors.HexColor("#" + HEX_TEAL)
COLOR_TERRACOTTA = colors.HexColor("#" + HEX_TERRACOTTA)
COLOR_TEXT_NAVY = colors.HexColor("#" + HEX_TEXT_NAVY)
COLOR_TEXT_MUTED = colors.HexColor("#" + HEX_TEXT_MUTED)
COLOR_BORDER = colors.HexColor("#" + HEX_BORDER)
COLOR_BG_LIGHT = colors.HexColor("#" + HEX_BG_LIGHT)
COLOR_MINT_TINT = colors.HexColor("#" + HEX_MINT_TINT)

# =============================================================================
# 1. DOCX GENERATION HELPERS & BUILDER
# =============================================================================

def set_cell_background(cell, hex_color):
    tcPr = cell._tc.get_or_add_tcPr()
    tcPr.append(parse_xml(f'<w:shd {nsdecls("w")} w:fill="{hex_color}"/>'))

def set_cell_margins(cell, top=120, bottom=120, left=160, right=160):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(
        f'<w:tcMar {nsdecls("w")}>'
        f'<w:top w:w="{top}" w:type="dxa"/>'
        f'<w:bottom w:w="{bottom}" w:type="dxa"/>'
        f'<w:left w:w="{left}" w:type="dxa"/>'
        f'<w:right w:w="{right}" w:type="dxa"/>'
        f'</w:tcMar>'
    )
    tcPr.append(tcMar)

def add_callout(doc, text, title=None, hex_accent=HEX_TEAL, hex_bg=HEX_MINT_TINT):
    tbl = doc.add_table(rows=1, cols=1)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    cell = tbl.cell(0, 0)
    set_cell_background(cell, hex_bg)
    set_cell_margins(cell, top=140, bottom=140, left=200, right=160)
    
    # Left thick border, no other borders
    tcPr = cell._tc.get_or_add_tcPr()
    borders = parse_xml(
        f'<w:tcBorders {nsdecls("w")}>'
        f'<w:left w:val="single" w:sz="36" w:space="0" w:color="{hex_accent}"/>'
        f'<w:top w:val="none"/>'
        f'<w:right w:val="none"/>'
        f'<w:bottom w:val="none"/>'
        f'</w:tcBorders>'
    )
    tcPr.append(borders)
    
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(2)
    p.paragraph_format.space_after = Pt(2)
    p.paragraph_format.line_spacing = 1.15
    if title:
        r_title = p.add_run(f"NOTE: {title}\n")
        r_title.bold = True
        r_title.font.size = Pt(10)
        r_title.font.color.rgb = RGBColor(0x15, 0x9B, 0x73) if hex_accent == HEX_TEAL else RGBColor(0xC1, 0x5D, 0x4A)
    
    r_body = p.add_run(text)
    r_body.font.size = Pt(9.5)
    r_body.font.color.rgb = RGBColor(0x14, 0x21, 0x3D)
    
    # Space after table
    sp = doc.add_paragraph()
    sp.paragraph_format.space_before = Pt(0)
    sp.paragraph_format.space_after = Pt(6)

def format_table(table, col_widths, col_alignments=None):
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    for r_idx, row in enumerate(table.rows):
        is_header = (r_idx == 0)
        for c_idx, cell in enumerate(row.cells):
            cell.width = Inches(col_widths[c_idx])
            set_cell_margins(cell, top=100, bottom=100, left=140, right=140)
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            
            # Subtle cell borders
            tcPr = cell._tc.get_or_add_tcPr()
            bdr = parse_xml(
                f'<w:tcBorders {nsdecls("w")}>'
                f'<w:top w:val="single" w:sz="4" w:space="0" w:color="{HEX_BORDER}"/>'
                f'<w:bottom w:val="single" w:sz="6" w:space="0" w:color="{HEX_BORDER}"/>'
                f'<w:left w:val="none"/>'
                f'<w:right w:val="none"/>'
                f'</w:tcBorders>'
            )
            tcPr.append(bdr)
            
            if is_header:
                set_cell_background(cell, HEX_TEAL)
                for p in cell.paragraphs:
                    p.paragraph_format.space_before = Pt(4)
                    p.paragraph_format.space_after = Pt(4)
                    if col_alignments and c_idx < len(col_alignments):
                        p.alignment = col_alignments[c_idx]
                    for run in p.runs:
                        run.font.bold = True
                        run.font.size = Pt(9)
                        run.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
            else:
                bg = HEX_BG_LIGHT if r_idx % 2 == 1 else "FFFFFF"
                set_cell_background(cell, bg)
                for p in cell.paragraphs:
                    p.paragraph_format.space_before = Pt(3)
                    p.paragraph_format.space_after = Pt(3)
                    if col_alignments and c_idx < len(col_alignments):
                        p.alignment = col_alignments[c_idx]
                    for run in p.runs:
                        run.font.size = Pt(9)
                        run.font.color.rgb = RGBColor(0x14, 0x21, 0x3D)

def build_docx_document():
    print("Generating Word document (.DOCX)...")
    doc = Document()
    
    # ── Page Setup (A4, 1 inch margins) ──────────────────────────────────────
    for section in doc.sections:
        section.page_width = Inches(8.27)
        section.page_height = Inches(11.69)
        section.top_margin = Inches(1.0)
        section.bottom_margin = Inches(1.0)
        section.left_margin = Inches(1.0)
        section.right_margin = Inches(1.0)
        
        # Configure Header & Footer
        header = section.header
        p_hdr = header.paragraphs[0]
        p_hdr.text = "PropKart v2.1.1 — Software Requirements & UI/UX Specification"
        p_hdr.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        p_hdr.runs[0].font.size = Pt(8)
        p_hdr.runs[0].font.color.rgb = RGBColor(0x64, 0x74, 0x8B)
        
        footer = section.footer
        p_ftr = footer.paragraphs[0]
        p_ftr.text = "CONFIDENTIAL & PROPRIETARY — NB PROPERTY TECH  |  SRS-PK-V2.1.1-DES-UIUX-001"
        p_ftr.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_ftr.runs[0].font.size = Pt(8)
        p_ftr.runs[0].font.color.rgb = RGBColor(0x94, 0xA3, 0xB8)
        
    # ── Cover Page ───────────────────────────────────────────────────────────
    if os.path.exists(LOCKUP_LOGO):
        doc.add_picture(LOCKUP_LOGO, width=Inches(2.5))
        p_img = doc.paragraphs[-1]
        p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_img.paragraph_format.space_before = Pt(40)
        p_img.paragraph_format.space_after = Pt(20)
        
    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_title = p_title.add_run("SOFTWARE REQUIREMENTS SPECIFICATION\n& UI/UX DESIGN SYSTEM SPECIFICATION")
    r_title.bold = True
    r_title.font.size = Pt(22)
    r_title.font.color.rgb = RGBColor(0x15, 0x9B, 0x73) # Primary Teal
    p_title.paragraph_format.space_after = Pt(8)
    
    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_sub = p_sub.add_run("Product: PropKart Real Estate Operating System & Desk CRM\nRelease: Version 2.1.1 (Build 10+)")
    r_sub.font.size = Pt(13)
    r_sub.font.color.rgb = RGBColor(0xC1, 0x5D, 0x4A) # Terracotta
    p_sub.paragraph_format.space_after = Pt(36)
    
    # Metadata Table
    meta_table = doc.add_table(rows=6, cols=2)
    meta_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    meta_data = [
        ("Document Identifier", "SRS-PK-V2.1.1-DES-UIUX-001"),
        ("Parent Organization", "NB Property Tech"),
        ("Target Roles", "Lead Graphics Designer, Principal UI/UX Designer, Frontend/Flutter Engineers"),
        ("Issue Date", "September 12, 2026"),
        ("Classification", "Internal / Proprietary — Product & UI/UX Baseline"),
        ("Target Build", "Production Release v2.1.1 (Flutter Material 3 / CRM Design System)"),
    ]
    for idx, (label, val) in enumerate(meta_data):
        c0 = meta_table.cell(idx, 0)
        c1 = meta_table.cell(idx, 1)
        c0.text = label
        c1.text = val
        c0.width = Inches(2.2)
        c1.width = Inches(4.0)
        set_cell_background(c0, HEX_BG_LIGHT)
        set_cell_background(c1, "FFFFFF")
        set_cell_margins(c0, top=80, bottom=80, left=120, right=120)
        set_cell_margins(c1, top=80, bottom=80, left=120, right=120)
        c0.paragraphs[0].runs[0].font.bold = True
        c0.paragraphs[0].runs[0].font.size = Pt(9)
        c0.paragraphs[0].runs[0].font.color.rgb = RGBColor(0x14, 0x21, 0x3D)
        c1.paragraphs[0].runs[0].font.size = Pt(9)
        c1.paragraphs[0].runs[0].font.color.rgb = RGBColor(0x64, 0x74, 0x8B)
        
    doc.add_page_break()
    
    # ── Helper for Sections ──────────────────────────────────────────────────
    def add_h1(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(18)
        p.paragraph_format.space_after = Pt(6)
        p.paragraph_format.keep_with_next = True
        r = p.add_run(text)
        r.bold = True
        r.font.size = Pt(16)
        r.font.color.rgb = RGBColor(0x15, 0x9B, 0x73) # Teal
        return p

    def add_h2(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(14)
        p.paragraph_format.space_after = Pt(4)
        p.paragraph_format.keep_with_next = True
        r = p.add_run(text)
        r.bold = True
        r.font.size = Pt(13)
        r.font.color.rgb = RGBColor(0xC1, 0x5D, 0x4A) # Terracotta
        return p

    def add_h3(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(10)
        p.paragraph_format.space_after = Pt(2)
        p.paragraph_format.keep_with_next = True
        r = p.add_run(text)
        r.bold = True
        r.font.size = Pt(11)
        r.font.color.rgb = RGBColor(0x14, 0x21, 0x3D) # Navy
        return p

    def add_p(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(2)
        p.paragraph_format.space_after = Pt(5)
        p.paragraph_format.line_spacing = 1.15
        r = p.add_run(text)
        r.font.size = Pt(10)
        r.font.color.rgb = RGBColor(0x14, 0x21, 0x3D)
        return p

    def add_bullet(bold_prefix, text):
        p = doc.add_paragraph(style='List Bullet')
        p.paragraph_format.space_before = Pt(1)
        p.paragraph_format.space_after = Pt(3)
        p.paragraph_format.line_spacing = 1.15
        r_bold = p.add_run(bold_prefix + " ")
        r_bold.bold = True
        r_bold.font.size = Pt(9.5)
        r_bold.font.color.rgb = RGBColor(0x14, 0x21, 0x3D)
        r_text = p.add_run(text)
        r_text.font.size = Pt(9.5)
        r_text.font.color.rgb = RGBColor(0x14, 0x21, 0x3D)
        return p

    # ── Section 1: Executive Summary ─────────────────────────────────────────
    add_h1("1. EXECUTIVE SUMMARY & SYSTEM ARCHITECTURE")
    add_h2("1.1 Product Purpose & Value Proposition")
    add_p("PropKart is not a public classifieds listing portal. It is an enterprise-grade, high-performance Real Estate Operating System & Desk CRM built specifically for real-estate brokers, agencies, telecallers, and sales executives.")
    add_p("The platform provides a unified workspace to manage both Rental and Re-Sale inventory at scale. It handles the complete deal lifecycle: multi-channel ad lead ingestion (Meta Lead Ads, Google Sheets), intelligent demand matchmaking, one-tap WhatsApp sharing, site visit scheduling, negotiation management, and deal closing documentation.")

    add_h2("1.2 Core Product Pillars of v2.1.1")
    add_bullet("Unified Dual Inventory (Rent & Re-Sale):", "Independent operations with dedicated visual atmospheres for Rental and Re-Sale portfolios.")
    add_bullet("Automated Demand Matchmaking:", "Real-time pairing of buyer/tenant requirements against active inventory using budget brackets (10% tolerance), BHK configurations, furnishing, and localities.")
    add_bullet("One-Tap Client Sharing:", "Instant generation of branded multi-property PDF dossiers, WhatsApp broadcast messages, and trackable public web shortlists.")
    add_bullet("Direct Inbound Marketing Ingestion:", "Real-time webhook inbox for Meta Lead Ads (Facebook & Instagram) and Google Sheets with lead intelligence, duplicate phone detection, and 1-click promotion to CRM.")
    add_bullet("Role-Aware Security & Permission Matrix:", "4 operational roles (Super Admin, Admin, Sales, Telecaller) governed by an interactive 40-metric permission control center.")
    add_bullet("Internal Team Messenger:", "Dedicated real-time team communication desk (/messages) with role filtering and Super Admin cross-team thread oversight.")

    add_h2("1.3 Technical Architecture Overview")
    add_bullet("Front-End Layer:", "Flutter (Dart ^3.11.1) with Material 3 and custom CRM Design System.")
    add_bullet("State Management:", "BLoC (flutter_bloc 9.1.1) for domain event handling + Riverpod for reactive local caching.")
    add_bullet("Persistence & Offline Sync:", "Isar embedded NoSQL database for rapid offline CRM querying + flutter_secure_storage for encrypted JWT credentials.")
    add_bullet("Target Platforms:", "Web (PWA at propkart.nbpropertytech.com), Android, iOS, Windows Desktop, macOS Desktop.")

    # ── Section 2: Design System ─────────────────────────────────────────────
    add_h1("2. DESIGN SYSTEM & UI TOKEN ARCHITECTURE")
    add_p("The PropKart design system follows Apple Human Interface Guidelines (HIG) combined with SaaS enterprise ergonomics. Long desk sessions require low eye fatigue, WCAG AAA contrast compliance, and high information density.")

    add_h2("2.1 Dual-Theme Architecture & Color Palette")
    add_p("The system implements runtime theming via ThemeManager. It supports Light and Dark modes across two master presets, with an Atmosphere Shift between Rental and Re-Sale desks.")
    
    # Palette Table
    p_tbl = doc.add_table(rows=15, cols=4)
    palette_data = [
        ("Token Role", "Modern Teal (Default SaaS)", "PropKart Classic (Terracotta)", "Dark Mode Override"),
        ("primary", "#159B73 (Emerald Teal)", "#C15D4A (Terracotta Clay)", "#10B981 / #D47A66"),
        ("primaryHover", "#128764", "#A64C3C", "#34D399 / #E08B78"),
        ("accent", "#E8F5F1 (Mint Wash)", "#F6D8D0 (Sand Tint)", "#0D3D31 / #3A2824"),
        ("rentalAtmosphere", "#159B73 (Fresh Teal)", "#5F8064 (Sage Green)", "#10B981 / #5F8064"),
        ("resaleAtmosphere", "#C15D4A (Warm Terracotta)", "#8B4513 (Saddle Wood)", "#D47A66 / #8B4513"),
        ("canvas", "#F8FAFC (Slate Canvas)", "#F4F4F3 (Warm Alabaster)", "#0F172A (Deep Slate)"),
        ("surface (Cards)", "#FFFFFF (Pure White)", "#FFFFFF (Neutral Card)", "#1E293B (Midnight Surface)"),
        ("border / divider", "#E8ECF2 (Light Gray)", "#E3DDD7 (Muted Sand)", "#334155 (Slate Border)"),
        ("textPrimary", "#14213D (Deep Navy Ink)", "#1A1A1A (Carbon Charcoal)", "#F8FAFC (Off-White)"),
        ("textSecondary", "#64748B (Slate Muted)", "#68738A (Clay Charcoal)", "#94A3B8 (Cool Slate)"),
        ("whatsappGreen", "#25D366 (WhatsApp Official)", "#25D366 (WhatsApp Official)", "#25D366"),
        ("success", "#10B981 (Mint Emerald)", "#5F8064 (Sage Success)", "#10B981"),
        ("danger", "#E11D48 (Crimson Red)", "#DC2626 (Vibrant Ruby)", "#E11D48"),
        ("warning", "#F59E0B (Amber Gold)", "#C4924A (Sand Warning)", "#F59E0B"),
    ]
    for r_idx, row in enumerate(palette_data):
        for c_idx, val in enumerate(row):
            p_tbl.cell(r_idx, c_idx).text = val
    format_table(p_tbl, [1.4, 1.8, 1.8, 1.4])

    add_callout(
        doc,
        "When the desk operates in Rental Mode, primary buttons, status pills, and active filter tabs accent in Teal / Sage. When toggled to Re-Sale Mode, the accent shifts to Terracotta / Clay. This prevents agents from accidentally pitching rental properties to resale buyers.",
        title="Atmosphere Shift Directive",
        hex_accent=HEX_TERRACOTTA,
        hex_bg="FDF6F0"
    )

    add_h2("2.2 Typography Hierarchy (SF Pro / Inter)")
    add_p("Apple platforms render SF Pro; Windows, Android, and Web render Inter via Google Fonts.")
    
    # Typography Table
    t_tbl = doc.add_table(rows=10, cols=6)
    type_data = [
        ("Token", "Size", "Weight", "Line Height", "Tracking", "Primary Usage"),
        ("largeDisplay", "32 pt", "Bold (700)", "40 pt", "-0.02 em", "Splash, Hero KPIs, Auth headers"),
        ("pageTitle", "24 pt", "Bold (700)", "32 pt", "-0.015 em", "Screen headers (Properties, Leads)"),
        ("sectionTitle", "18 pt", "SemiBold (600)", "24 pt", "-0.01 em", "Card headers, modal titles"),
        ("cardTitle", "15 pt", "SemiBold (600)", "20 pt", "-0.01 em", "Property card titles, requirement codes"),
        ("bodyMedium", "14 pt", "Medium (500)", "20 pt", "0.0 em", "Form inputs, table cell content"),
        ("body", "13.5 pt", "Regular (400)", "18 pt", "0.0 em", "Descriptions, remarks, chat bubbles"),
        ("captionBold", "12 pt", "SemiBold (600)", "16 pt", "+0.01 em", "Status badges, table column headers"),
        ("caption", "11 pt", "Regular (400)", "14 pt", "+0.01 em", "Timestamps, secondary subtitles"),
        ("footnote", "10 pt", "Medium (500)", "12 pt", "+0.02 em", "Unread counts, validation error text"),
    ]
    for r_idx, row in enumerate(type_data):
        for c_idx, val in enumerate(row):
            t_tbl.cell(r_idx, c_idx).text = val
    format_table(t_tbl, [1.2, 0.7, 1.1, 0.9, 0.8, 1.7])

    add_h2("2.3 Spacing, Radii, Elevation & Glassmorphism")
    add_bullet("Spacing Scale (CRMSpacing):", "xs: 4px | s: 8px | m: 12px | l: 16px | xl: 20px | xxl: 24px | xxxl: 32px | huge: 48px | mega: 64px.")
    add_bullet("Corner Radii (CRMBorderRadius):", "xs: 4px | s: 8px (Inputs) | m: 12px (Cards) | l: 16px (Panels) | xl: 20px (Modals) | pill: 999px (Chips/Pills).")
    add_bullet("Elevation & Shadows (CRMShadows):", "soft: 0px 2px 8px rgba(0,0,0,0.04) | medium: 0px 6px 16px rgba(0,0,0,0.08) | floating: 0px 12px 32px rgba(0,0,0,0.12) | primaryGlow: 0px 4px 14px rgba(21,155,115,0.35).")
    add_bullet("Glassmorphism Tokens (CRMBlur):", "Navigation: 20px blur with 82% surface opacity fill. Avoid continuous blur on long virtualized scrolling lists.")
    add_bullet("Responsive Breakpoints:", "Mobile: < 768px | Tablet: 768px – 1023px | Desktop: 1024px – 1439px | Ultrawide: >= 1440px (Max content bounded to 1440px centered).")

    # ── Section 3: App Shell ─────────────────────────────────────────────────
    add_h1("3. GLOBAL APPLICATION SHELL ARCHITECTURE")
    add_h2("3.1 Resizable Responsive Sidebar (ModernSidebar)")
    add_p("The sidebar maintains persistent desk context across desktop viewports. Width is dynamically resizable between 245px and 320px via a vertical drag handle (or collapses to 70px icon-only rail).")
    add_bullet("Branding:", "CRMBrandLockup rendering official 38px home icon and bold wordmark.")
    add_bullet("Navigation Items:", "Dashboard (/dashboard), Properties (/properties), Leads (/requirements) with numeric unread count pill, Employees (/users), Reports (/reports), Campaign (/campaign), Library (/library), Settings (/settings), Recycle Bin (/bin).")
    add_bullet("User Footer:", "UserProfileCard with avatar initials, full name, role pill, and instant sign-out action.")

    add_h2("3.2 Glass Modern Top Bar (ModernTopBar)")
    add_bullet("Omni-Search Field:", "420px max width pill search bar with 300ms debouncing. Searches across properties, leads, owners, and builders with a categorized glass dropdown overlay.")
    add_bullet("Quick Add (+) Action Button:", "Primary teal circular button (38px diameter) with primary glow shadow. Opens quick action modal (Add Property, Add Lead, Schedule Visit).")
    add_bullet("Notification Center (Bell):", "Outlined bell with unread badge dot; toggles right-sliding notification drawer.")
    add_bullet("Team Messages (Chat):", "Outlined message icon with blue badge; directly navigates to /messages.")
    add_bullet("Super Admin Menu:", "Avatar dropdown with profile link, session sign-out, and 'Set System Default Theme' modal.")

    add_h2("3.3 Mobile Persistent Bottom Navigation Bar")
    add_p("On mobile devices (< 768px), the sidebar is hidden and replaced by persistent_bottom_nav_bar_v2 containing: 0: Dashboard, 1: Properties, 2: Center Quick Add (+), 3: Leads (with badge), 4: Profile & Settings.")

    # ── Section 4: RBAC & Permission Matrix ──────────────────────────────────
    add_h1("4. ROLE-BASED ACCESS CONTROL (RBAC) & PERMISSION MATRIX")
    add_p("PropKart v2.1.1 features an enterprise-grade Permission Matrix Service (PermissionMatrixService) with 40+ granular controllable permissions across 7 categories.")
    
    # RBAC Table
    r_tbl = doc.add_table(rows=14, cols=5)
    rbac_data = [
        ("Feature / Capability", "Super Admin", "Admin", "Sales", "Telecaller"),
        ("View Dashboard, Properties, Leads", "YES", "YES", "YES", "YES"),
        ("Rent vs Re-Sale Atmosphere Switch", "YES", "YES", "YES", "YES"),
        ("Create & Edit Properties", "YES", "YES", "YES", "YES"),
        ("Soft Delete to Recycle Bin", "YES", "YES", "NO", "NO"),
        ("Restore / Permanent Drop", "YES (Full)", "YES (Restore)", "NO", "NO"),
        ("Verify Property (Blue Checkmark)", "YES", "YES", "NO", "NO"),
        ("Export Properties / Leads (Excel)", "YES", "YES", "NO", "NO"),
        ("View Unmasked Client Phone", "YES", "YES", "YES", "Masked Option"),
        ("Inbound Campaign Leads Queue", "YES", "YES", "NO", "YES (Intake)"),
        ("Manage Webhooks & Google Sheets", "YES", "YES", "NO", "NO"),
        ("1-Click Move Lead to CRM", "YES", "YES", "NO", "YES"),
        ("Executive Reports & BI", "YES", "YES", "NO", "NO"),
        ("Permission Matrix & System Lock", "YES (Exclusive)", "NO", "NO", "NO"),
    ]
    for r_idx, row in enumerate(rbac_data):
        for c_idx, val in enumerate(row):
            r_tbl.cell(r_idx, c_idx).text = val
    format_table(r_tbl, [2.0, 1.1, 1.1, 1.0, 1.2])

    # ── Section 5: Screen-by-Screen Specifications ───────────────────────────
    add_h1("5. COMPLETE SCREEN-BY-SCREEN FUNCTIONAL SPECIFICATIONS")
    
    add_h2("5.1 Authentication & Gatekeeper Screens")
    add_bullet("/splash:", "Pulsating brand shimmer animation, startup Isar sync warmup, session expiry evaluation (9-hour inactivity limit).")
    add_bullet("/get-started:", "Apple-style clean presentation card with 'Sign In to Desk' primary CTA.")
    add_bullet("/login:", "Email, password with visibility toggle, rate-limiting banners, and forgot password link.")
    add_bullet("/reset-password:", "Secure recovery token verification with password strength meter.")
    add_bullet("/terms-and-conditions & /privacy-policy:", "Full-screen clean document readers.")

    add_h2("5.2 Executive Dashboard (/dashboard)")
    add_bullet("Welcome Header:", "Personalized greeting (Good Morning / Afternoon / Evening), user name, calendar date, and Rent vs Re-Sale atmosphere switcher.")
    add_bullet("KPI Metric Cards (CRMKPICard):", "4-column desktop / 2-column mobile grid: Total Listed Inventory (+% growth), Available Units, Deals Closed, Active Requirements, Registered Team Roster.")
    add_bullet("Today's Schedule Card:", "Client site visits agenda with time, property code link, client name, assigned executive, status pill, and WhatsApp action.")
    add_bullet("Priority Follow-ups Card:", "Sub-tabs (Today, Due, Future) with client budget, configuration, and direct phone/WhatsApp shortcuts.")
    add_bullet("Analytics Section:", "Residential vs Commercial pie chart + Top Localities inventory density bar chart.")
    add_bullet("Team Quick Notes:", "Scratchpad checklist with optimistic check/uncheck updates.")

    add_h2("5.3 Properties Inventory Hub (/properties & /properties/:id)")
    add_bullet("Atmosphere & Category Strip:", "Rent vs Re-Sale toggle, Residential vs Commercial tabs, BHK chips (1 BHK, 2 BHK, 3 BHK, 4+ BHK, RK, Plot, Office, Shop).")
    add_bullet("Desk Toolstrip:", "Omni-search, Locality multi-select, Price range sliders (₹ Lacs / ₹ Crores), Image status filter (With Images, No Images), 'My Added Only' toggle, Card Grid vs Data Table switcher, Compare checkboxes.")
    add_bullet("Property Card Anatomy:", "Thumbnail carousel with counter (1/8), formatted price header, size badge (Super Built-up & Carpet), Verified Blue Badge, property code, owner WhatsApp contact row, action menu (Edit, Share, Delete).")
    add_bullet("Side-by-Side Comparison Modal:", "Evaluates up to 4 properties across 15 structured parameters (Price, Deposit, Carpet, Floor, Age, Facing, Furnishing, Parking, Bathrooms, Balconies, Maintenance).")
    add_bullet("Add / Edit Property Wizard (AddEditPropertyScreen):", "7-step comprehensive form: 1. Basic Identity, 2. Location & Interactive Map Pin Picker (reverse geocoding to lat/long), 3. Dimensions & Spaces, 4. Commercials (1-6 month deposit calculator), 5. Specifications & Amenities, 6. Media Uploader (image compression & Cloudinary upload), 7. Ownership & Internal Remarks. Includes CRMDraftRepository for autosave restoration.")
    add_bullet("Property Detail Screen (/properties/:id):", "Full-bleed gallery, spec chips, map view, owner quick-action card, client sharing drawer.")

    add_h2("5.4 Recycle Bin (/bin)")
    add_bullet("Soft Delete Vault:", "Displays deleted property listings and client requirements with deletion timestamp and retention countdown.")
    add_bullet("Actions:", "1-click Optimistic Restore back to active inventory or Permanent Drop (Super Admin exclusive).")

    add_h2("5.5 Leads & Requirements Hub (/requirements)")
    add_bullet("Main Tabs:", "Active Leads, Requirements, Scheduled Follow-ups.")
    add_bullet("14-Stage Deal Progression Funnel:", "Tracks leads through 14 standardized states: 1. Lead Created -> 2. Requirement Added -> 3. Requirement Verified -> 4. Matching Started -> 5. Properties Matched -> 6. Properties Shared -> 7. Client Viewed -> 8. Client Interested -> 9. Site Visit Scheduled -> 10. Site Visit Completed -> 11. Negotiation -> 12. Booking Token -> 13. Documentation -> 14. Closed / Won.")
    add_bullet("Automated Matchmaking Engine:", "Evaluates client budget (10% tolerance), localities, BHK, furnishing, and facing against active inventory. Computes Match Readiness Score (Ready, Needs Information, Cannot Match) and Requirement Quality Metric (High, Medium, Low, Poor).")
    add_bullet("Client Sharing Suite:", "Branded PDF Dossier Generator (PropertySharePdf), Public Web Shortlist Link (/share/:sessionId) with view tracker, and pre-templated WhatsApp broadcast.")
    add_bullet("Follow-up System:", "Calendar & clock alarm picker modal. Strictly isolates external followups from internal_crm_remarks audit trail.")

    add_h2("5.6 Campaign & Inbound Marketing Ingestion (/campaign)")
    add_bullet("Dual-Section Isolation:", "Segregates inbound records into two non-overlapping pipelines: Property Listing Leads vs Requirement Leads.")
    add_bullet("Lead Intelligence Engine:", "Parses raw text responses from Meta custom questions and Google Forms to extract budget, BHK, and localities. Detects duplicate phone numbers across the database.")
    add_bullet("Interactive Status Dropdown:", "Follow-up (opens schedule modal), Interested (green highlight & 1-click Move to CRM), Not Interested (moves to archive tab).")
    add_bullet("1-Click 'Move to CRM':", "Promotes campaign lead into a permanent property or requirement while preserving ad attribution metadata (meta_lead_id, campaign_name).")
    add_bullet("Connections Screen (/campaign/connections):", "Meta Lead Ads webhook setup, Verify Token, Google Sheets sync URL, and JSON payload simulator.")

    add_h2("5.7 Internal Team Messenger (/messages)")
    add_bullet("Layout:", "Master-detail responsive split layout (Roster list 320px on left, chat thread on right).")
    add_bullet("Super Admin Team Grouping:", "Roster grouped by teams with 'Propkart Admin' pinned first. Super Admins can inspect cross-team threads.")
    add_bullet("Roster Filtering:", "All, Admins, Telecallers, Sales with unread message badges and active status indicators.")
    add_bullet("Chat Canvas:", "Branded chat bubbles, timestamps, delivery checkmarks, and keyboard shortcuts (Enter to send, Shift+Enter for newline).")

    add_h2("5.8 Reports & Business Intelligence (/reports)")
    add_bullet("Global Filter Bar:", "Date presets (Today, Yesterday, Last 7 Days, This Month, Custom Range, All Time) + Team/Agent dimension filter.")
    add_bullet("Overall Business Insight (/reports/leads/overall-business-insight):", "Executive revenue projections, 14-stage lead conversion funnel, callback velocity metrics, team leaderboard & rankings, and lead source attribution donut chart.")
    add_bullet("Export Options:", "1-click export of executive dossiers in .xlsx and formatted .pdf.")

    add_h2("5.9 Shared Document Libraries (/library)")
    add_bullet("Rental Library (/rental-library):", "Lease agreements, tenant/landlord KYC proofs, deposit receipts, utility clearances, inspection media.")
    add_bullet("Re-Sale Library (/resale-library):", "Sale deeds, title clearances, society NOCs, floor plans, tax receipts, loan sanction letters.")
    add_bullet("Service Agent Library (/service-agent-library):", "Contractor agreements, GST certificates, SLAs, and completed work showcases for electricians, plumbers, and cleaning crews.")

    add_h2("5.10 Directories & Team Administration")
    add_bullet("Client Index (/clients):", "Buyer/tenant directory with Kanban Pipeline vs Data Table switcher.")
    add_bullet("Property Owners (/owners):", "Landlord registry linked to properties owned with rental yield summaries.")
    add_bullet("Builders & Developers (/builders):", "Developer directory with tier ratings, active projects, and POCs.")
    add_bullet("Employees & Users (/users):", "Staff directory, user creation modal, password reset queue tab, and agent activity drawer.")
    add_bullet("Settings & Governance (/settings):", "Profile editor, Theme customizer with 'Make as System Default', Location manager (cities/localities), Super Admin Permission Matrix Card, Security Audit Logs (/settings/audit-logs), and Sync Diagnostics (/settings/sync-debug).")

    # ── Section 6: User Workflows ────────────────────────────────────────────
    add_h1("6. USER WORKFLOWS & STATE TRANSITION DIRECTIVES")
    add_h2("6.1 Inbound Lead-to-Close Pipeline")
    add_p("1. Ingestion: Inbound lead captured from Meta Ads or Google Sheet into Campaign Inbox.")
    add_p("2. Qualification: Telecaller conducts initial call. If Interested, selects 'Move to CRM' with 1 click.")
    add_p("3. Matchmaking: Requirement created (REQ-R-XXXXXX). Matchmaking engine queries live inventory.")
    add_p("4. Client Sharing: Sales agent generates branded PDF dossier or public shortlist link and shares via WhatsApp.")
    add_p("5. Inspection & Closing: Client views link (stage auto-updates). Site visit scheduled and completed. Commercial negotiation concluded, booking token logged, and legal deed archived in Library.")

    add_h2("6.2 Property Listing Lifecycle & Atmosphere Shift")
    add_p("1. Creation: Agent initiates listing. Form autosaves locally. Photos compressed and uploaded to Cloudinary.")
    add_p("2. Atmosphere Allocation: Listing assigned to Rental (Teal) or Re-Sale (Terracotta) book.")
    add_p("3. Active Matchmaking: Listing available for client matchmaking. Blue checkmark verified by Admin.")
    add_p("4. Archival: Listing moved to Recycle Bin (/bin) upon deal close or owner suspension, with 1-click restore.")

    # ── Section 7: Designer Directives ───────────────────────────────────────
    add_h1("7. UI/UX DESIGNER IMPLEMENTATION DIRECTIVES")
    add_h2("7.1 Layout & Spatial Rules")
    add_bullet("Auto-Layout Mandatory:", "Never design fixed-width frames in Figma. Test across 390px (Mobile), 834px (Tablet), and 1440px (Desktop).")
    add_bullet("Information Density:", "PropKart is an enterprise productivity CRM. Avoid oversized empty hero banners. Maintain high information density, clear typography contrast, and compact padding.")
    add_bullet("Atmosphere Cues:", "Always provide clear visual cues distinguishing Rental Mode (cool teal) from Re-Sale Mode (warm terracotta).")

    add_h2("7.2 Component Design Specifications")
    add_bullet("Buttons:", "Primary: brand fill + primaryGlow shadow (press scale 0.98). Secondary: 1px border. WhatsApp: official #25D366 green. Destructive: crimson #E11D48 outline.")
    add_bullet("Form Inputs:", "44px height, 8px radius. 1px border #E8ECF2 (Light) / #334155 (Dark). Focused: 1.5px brand border with outer glow ring. Include ₹ prefix and format badges.")
    add_bullet("Status Chips:", "24px height, 12px radius. Translucent wash (12% opacity) with high-contrast label: Emerald (Active/Verified), Amber (Follow-up), Slate (Closed), Crimson (Alert).")
    add_bullet("Modals & Drawers:", "Modals: 20px radius, max width 540px, frosted glass backdrop (sigma 24). Drawers: slide from right on desktop/tablet, slide from bottom on mobile.")

    add_h2("7.3 Mandatory 5 States per Screen")
    add_p("Every screen wireframe must include 5 explicit states:")
    add_bullet("1. Default Loaded State:", "Complete data populated with interactive controls.")
    add_bullet("2. Skeleton Loading State:", "Shimmering placeholder cards matching exact dimensions of text blocks and images (no generic circular spinners in data tables).")
    add_bullet("3. Empty State:", "Friendly graphic illustration with explanatory title and a single clear primary CTA.")
    add_bullet("4. Error State:", "Clear error icon with non-technical explanation and a Retry action button.")
    add_bullet("5. Permission Denied State (CRMPermissionDenied):", "Shield lock icon with 'Access Restricted. Contact your Super Administrator'.")

    # ── Section 8: Master Route Index ────────────────────────────────────────
    add_h1("8. MASTER ROUTE & PERMISSION INDEX TABLE")
    
    # Route Table
    rt_tbl = doc.add_table(rows=18, cols=4)
    route_data = [
        ("Screen Name", "Route URL", "Allowed Roles", "Primary Layout"),
        ("Splash & Sync", "/splash", "Public / System", "Responsive Fullscreen"),
        ("Get Started", "/get-started", "Unauthenticated", "Centered Presentation Card"),
        ("Login Screen", "/login", "Unauthenticated", "Centered Auth Card"),
        ("Password Reset", "/reset-password", "Recovery Link", "Centered Form Card"),
        ("Dashboard", "/dashboard", "All 4 Roles", "4-Col Grid / Mobile Stack"),
        ("Properties CRM", "/properties", "All 4 Roles", "Data Table & 3-Col Cards"),
        ("Property Detail", "/properties/:id", "All 4 Roles", "Hero Gallery & Split Specs"),
        ("Leads & Matching", "/requirements", "All 4 Roles", "Pipeline Cards & Table"),
        ("Public Share Link", "/share/:sessionId", "Public Client", "Responsive Web Portal"),
        ("Campaign Inbox", "/campaign/leads", "SuperAdmin, Admin, TC", "High-Density Table"),
        ("Campaign Connectors", "/campaign/connections", "SuperAdmin, Admin", "Form & Payload Inspector"),
        ("Team Messenger", "/messages", "All 4 Roles", "Master-Detail Split Canvas"),
        ("Overall Business Report", "/reports/leads/overall..", "SuperAdmin, Admin", "Charts & KPI Dossier"),
        ("Document Library", "/library", "All 4 Roles", "Category 3-Card Grid"),
        ("Client Index", "/clients", "All 4 Roles", "Kanban Board & Table"),
        ("Employees Directory", "/users", "SuperAdmin, Admin", "User Cards & Roster"),
        ("Recycle Bin", "/bin", "SuperAdmin, Admin", "High-Density Table"),
        ("System Settings", "/settings", "All 4 Roles", "Multi-Tab Master Panel"),
    ]
    rt_tbl = doc.add_table(rows=len(route_data), cols=4)
    for r_idx, row in enumerate(route_data):
        for c_idx, val in enumerate(row):
            rt_tbl.cell(r_idx, c_idx).text = val
    format_table(rt_tbl, [1.6, 1.6, 1.4, 1.6])

    # ── Section 9: Sign-off ──────────────────────────────────────────────────
    add_h1("9. DOCUMENT SIGN-OFF & REVISION APPROVAL")
    add_p("This document represents the formal software requirements specification and UI/UX handoff baseline for PropKart v2.1.1.")
    add_bullet("Product Architecture Approval:", "Lead Systems Architect, NB Property Tech")
    add_bullet("UI/UX Design Lead Approval:", "Principal UX Designer, NB Property Tech")
    add_bullet("Engineering Review:", "Lead Flutter Engineer & Core API Team")

    doc.save(DOCX_OUTPUT)
    print("DOCX generated successfully at:", DOCX_OUTPUT)


# =============================================================================
# 2. PDF GENERATION (REPORTLAB WITH RUNNING HEADERS & FOOTERS)
# =============================================================================

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_elements(num_pages)
            super().showPage()
        super().save()

    def draw_page_elements(self, page_count):
        if self._pageNumber > 1:  # Skip cover page
            self.saveState()
            self.setFont("Helvetica-Bold", 7.5)
            self.setFillColor(COLOR_TEXT_MUTED)
            
            # Running Header
            self.drawString(36, 805, "PropKart v2.1.1 — Software Requirements & UI/UX Specification")
            self.setStrokeColor(COLOR_BORDER)
            self.setLineWidth(0.5)
            self.line(36, 798, 559, 798)
            
            # Running Footer
            self.line(36, 45, 559, 45)
            self.setFont("Helvetica", 7.5)
            self.drawString(36, 32, "CONFIDENTIAL & PROPRIETARY — NB PROPERTY TECH (SRS-PK-V2.1.1-DES-UIUX-001)")
            page_str = f"Page {self._pageNumber} of {page_count}"
            self.drawRightString(559, 32, page_str)
            self.restoreState()

def build_pdf_document():
    print("Generating PDF document (.PDF)...")
    doc = SimpleDocTemplate(
        PDF_OUTPUT,
        pagesize=A4,
        leftMargin=36,
        rightMargin=36,
        topMargin=54,
        bottomMargin=54
    )
    
    styles = getSampleStyleSheet()
    
    title_style = ParagraphStyle(
        'CoverTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=20,
        leading=25,
        textColor=COLOR_TEAL,
        alignment=1, # Center
        spaceAfter=10
    )
    
    subtitle_style = ParagraphStyle(
        'CoverSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=11,
        leading=15,
        textColor=COLOR_TERRACOTTA,
        alignment=1, # Center
        spaceAfter=25
    )
    
    h1_style = ParagraphStyle(
        'CustomH1',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=13.5,
        leading=18,
        textColor=COLOR_TEAL,
        spaceBefore=14,
        spaceAfter=6,
        keepWithNext=True
    )
    
    h2_style = ParagraphStyle(
        'CustomH2',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=11,
        leading=15,
        textColor=COLOR_TERRACOTTA,
        spaceBefore=10,
        spaceAfter=4,
        keepWithNext=True
    )
    
    body_style = ParagraphStyle(
        'CustomBody',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.5,
        leading=12,
        textColor=COLOR_TEXT_NAVY,
        spaceBefore=2,
        spaceAfter=4
    )
    
    bullet_style = ParagraphStyle(
        'CustomBullet',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.5,
        leading=11.5,
        textColor=COLOR_TEXT_NAVY,
        leftIndent=12,
        firstLineIndent=-8,
        spaceBefore=1,
        spaceAfter=2
    )
    
    th_style = ParagraphStyle(
        'TH',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=7.5,
        leading=9.5,
        textColor=colors.white,
        alignment=0
    )
    
    td_style = ParagraphStyle(
        'TD',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=7.5,
        leading=9.5,
        textColor=COLOR_TEXT_NAVY,
        alignment=0
    )
    
    td_bold_style = ParagraphStyle(
        'TDBold',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=7.5,
        leading=9.5,
        textColor=COLOR_TEXT_NAVY,
        alignment=0
    )

    callout_style = ParagraphStyle(
        'Callout',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8,
        leading=11,
        textColor=COLOR_TEXT_NAVY
    )

    story = []

    # ── Cover Page ───────────────────────────────────────────────────────────
    story.append(Spacer(1, 30))
    if os.path.exists(LOCKUP_LOGO):
        story.append(Image(LOCKUP_LOGO, width=2.4*72, height=1.2*72))
        story.append(Spacer(1, 20))
        
    story.append(Paragraph("SOFTWARE REQUIREMENTS SPECIFICATION<br/>& UI/UX DESIGN SYSTEM SPECIFICATION", title_style))
    story.append(Paragraph("Product: PropKart Real Estate Operating System & Desk CRM<br/>Release: Version 2.1.1 (Production Build 10+)", subtitle_style))
    story.append(Spacer(1, 15))
    
    # Cover Metadata Table
    meta_rows = [
        [Paragraph("Document Identifier", td_bold_style), Paragraph("SRS-PK-V2.1.1-DES-UIUX-001", td_style)],
        [Paragraph("Parent Organization", td_bold_style), Paragraph("NB Property Tech", td_style)],
        [Paragraph("Target Audience", td_bold_style), Paragraph("Lead Graphics Designer, Principal UI/UX Designer, Frontend Engineers", td_style)],
        [Paragraph("Document Date", td_bold_style), Paragraph("September 12, 2026", td_style)],
        [Paragraph("Document Classification", td_bold_style), Paragraph("Internal / Proprietary — Product & UI/UX Baseline", td_style)],
        [Paragraph("Target Environment", td_bold_style), Paragraph("Production Release v2.1.1 (Flutter Material 3 / CRM Design System)", td_style)],
    ]
    t_meta = Table(meta_rows, colWidths=[150, 360])
    t_meta.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (0,-1), COLOR_BG_LIGHT),
        ('BACKGROUND', (1,0), (1,-1), colors.white),
        ('GRID', (0,0), (-1,-1), 0.5, COLOR_BORDER),
        ('TOPPADDING', (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(t_meta)
    story.append(PageBreak())

    # ── Section 1: Executive Summary ─────────────────────────────────────────
    story.append(Paragraph("1. EXECUTIVE SUMMARY & SYSTEM ARCHITECTURE", h1_style))
    story.append(Paragraph("1.1 Product Philosophy & Value Proposition", h2_style))
    story.append(Paragraph("PropKart is not a public classifieds portal. It is an enterprise-grade, high-performance Real Estate Operating System & Desk CRM built specifically for property brokers, sales teams, telecallers, and agency owners.", body_style))
    story.append(Paragraph("The platform provides a unified workspace to manage both Rental and Re-Sale inventory at scale. It handles the complete deal lifecycle: multi-channel ad lead ingestion (Meta Lead Ads, Google Sheets), intelligent demand matchmaking, one-tap WhatsApp sharing, site visit scheduling, negotiation management, and deal closing documentation.", body_style))
    
    story.append(Paragraph("1.2 Core Product Pillars of v2.1.1", h2_style))
    story.append(Paragraph("• <b>Unified Dual Inventory:</b> Seamless management across residential and commercial books with dedicated visual atmospheres.", bullet_style))
    story.append(Paragraph("• <b>Automated Matchmaking:</b> Real-time pairing of buyer/tenant requirements with active inventory using budget brackets (10% tolerance), BHK configurations, furnishing, and localities.", bullet_style))
    story.append(Paragraph("• <b>One-Tap Client Sharing:</b> Instant generation of branded multi-property PDF dossiers, WhatsApp broadcast messages, and trackable public web shortlists.", bullet_style))
    story.append(Paragraph("• <b>Direct Marketing Ingestion:</b> Webhooks for Meta Lead Ads and Google Sheets with lead intelligence, duplicate phone detection, and 1-click promotion to CRM.", bullet_style))
    story.append(Paragraph("• <b>Role-Aware Security & Permission Matrix:</b> 4 operational roles governed by a dynamic 40-metric permission control center.", bullet_style))
    story.append(Paragraph("• <b>Internal Team Messenger:</b> Dedicated real-time communication desk (/messages) with role filtering and Super Admin thread oversight.", bullet_style))

    story.append(Paragraph("1.3 Technical Architecture Overview", h2_style))
    story.append(Paragraph("• <b>Front-End Framework:</b> Flutter (Dart ^3.11.1) with Material 3 and custom CRM Design System.", bullet_style))
    story.append(Paragraph("• <b>State Management:</b> BLoC (flutter_bloc 9.1.1) for domain events + Riverpod for reactive caching.", bullet_style))
    story.append(Paragraph("• <b>Persistence:</b> Isar embedded NoSQL database for rapid offline querying + flutter_secure_storage for encrypted JWT credentials.", bullet_style))
    story.append(Paragraph("• <b>Target Platforms:</b> Web (PWA at propkart.nbpropertytech.com), Android, iOS, Windows Desktop, macOS Desktop.", bullet_style))

    # ── Section 2: Design System ─────────────────────────────────────────────
    story.append(Paragraph("2. DESIGN SYSTEM & UI TOKEN ARCHITECTURE", h1_style))
    story.append(Paragraph("2.1 Dual-Theme Architecture & Color Palette", h2_style))
    story.append(Paragraph("PropKart implements runtime theming via ThemeManager, supporting Light and Dark modes across two master presets with an Atmosphere Shift between Rental and Re-Sale desks.", body_style))

    # Palette Table in PDF
    palette_pdf_data = [
        [Paragraph("Token Role", th_style), Paragraph("Modern Teal (Default SaaS)", th_style), Paragraph("PropKart Classic (Terracotta)", th_style), Paragraph("Dark Mode Override", th_style)],
        [Paragraph("primary", td_bold_style), Paragraph("#159B73 (Emerald Teal)", td_style), Paragraph("#C15D4A (Terracotta Clay)", td_style), Paragraph("#10B981 / #D47A66", td_style)],
        [Paragraph("primaryHover", td_bold_style), Paragraph("#128764", td_style), Paragraph("#A64C3C", td_style), Paragraph("#34D399 / #E08B78", td_style)],
        [Paragraph("accent", td_bold_style), Paragraph("#E8F5F1 (Mint Wash)", td_style), Paragraph("#F6D8D0 (Sand Tint)", td_style), Paragraph("#0D3D31 / #3A2824", td_style)],
        [Paragraph("rentalAtmosphere", td_bold_style), Paragraph("#159B73 (Fresh Teal)", td_style), Paragraph("#5F8064 (Sage Green)", td_style), Paragraph("#10B981 / #5F8064", td_style)],
        [Paragraph("resaleAtmosphere", td_bold_style), Paragraph("#C15D4A (Warm Terracotta)", td_style), Paragraph("#8B4513 (Saddle Wood)", td_style), Paragraph("#D47A66 / #8B4513", td_style)],
        [Paragraph("canvas", td_bold_style), Paragraph("#F8FAFC (Slate Canvas)", td_style), Paragraph("#F4F4F3 (Warm Alabaster)", td_style), Paragraph("#0F172A (Deep Slate)", td_style)],
        [Paragraph("surface", td_bold_style), Paragraph("#FFFFFF (Pure White)", td_style), Paragraph("#FFFFFF (Neutral Card)", td_style), Paragraph("#1E293B (Midnight Surface)", td_style)],
        [Paragraph("border / divider", td_bold_style), Paragraph("#E8ECF2 (Light Gray)", td_style), Paragraph("#E3DDD7 (Muted Sand)", td_style), Paragraph("#334155 (Slate Border)", td_style)],
        [Paragraph("textPrimary", td_bold_style), Paragraph("#14213D (Deep Navy)", td_style), Paragraph("#1A1A1A (Carbon Charcoal)", td_style), Paragraph("#F8FAFC (Off-White)", td_style)],
        [Paragraph("textSecondary", td_bold_style), Paragraph("#64748B (Slate Muted)", td_style), Paragraph("#68738A (Clay Charcoal)", td_style), Paragraph("#94A3B8 (Cool Slate)", td_style)],
        [Paragraph("whatsappGreen", td_bold_style), Paragraph("#25D366 (Official)", td_style), Paragraph("#25D366 (Official)", td_style), Paragraph("#25D366", td_style)],
        [Paragraph("success / danger", td_bold_style), Paragraph("#10B981 / #E11D48", td_style), Paragraph("#5F8064 / #DC2626", td_style), Paragraph("#10B981 / #E11D48", td_style)],
    ]
    t_pal = Table(palette_pdf_data, colWidths=[90, 145, 145, 130])
    t_pal.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), COLOR_TEAL),
        ('GRID', (0,0), (-1,-1), 0.5, COLOR_BORDER),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, COLOR_BG_LIGHT]),
    ]))
    story.append(t_pal)
    story.append(Spacer(1, 6))

    # Callout in PDF
    callout_data = [[Paragraph("<b>UX Directive — Atmosphere Shift:</b> When the desk operates in <b>Rental Mode</b>, primary buttons, status pills, and active filter tabs accent in Teal / Sage. When toggled to <b>Re-Sale Mode</b>, the accent shifts to Terracotta / Clay. This prevents agents from accidentally pitching rental properties to resale buyers.", callout_style)]]
    t_callout = Table(callout_data, colWidths=[510])
    t_callout.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#FDF6F0")),
        ('LEFTPADDING', (0,0), (-1,-1), 12),
        ('RIGHTPADDING', (0,0), (-1,-1), 10),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('LINEBEFORE', (0,0), (0,-1), 3.0, COLOR_TERRACOTTA),
    ]))
    story.append(t_callout)
    story.append(Spacer(1, 8))

    story.append(Spacer(1, 4))

    # Typography Table in PDF
    type_pdf_data = [
        [Paragraph("Token", th_style), Paragraph("Size", th_style), Paragraph("Weight", th_style), Paragraph("Line Ht", th_style), Paragraph("Tracking", th_style), Paragraph("Usage Context", th_style)],
        [Paragraph("largeDisplay", td_bold_style), Paragraph("32 pt", td_style), Paragraph("Bold (700)", td_style), Paragraph("40 pt", td_style), Paragraph("-0.02 em", td_style), Paragraph("Splash, Hero KPIs, Auth welcome", td_style)],
        [Paragraph("pageTitle", td_bold_style), Paragraph("24 pt", td_style), Paragraph("Bold (700)", td_style), Paragraph("32 pt", td_style), Paragraph("-0.015 em", td_style), Paragraph("Screen headers (Properties, Leads)", td_style)],
        [Paragraph("sectionTitle", td_bold_style), Paragraph("18 pt", td_style), Paragraph("SemiBold (600)", td_style), Paragraph("24 pt", td_style), Paragraph("-0.01 em", td_style), Paragraph("Card headers, modal titles", td_style)],
        [Paragraph("cardTitle", td_bold_style), Paragraph("15 pt", td_style), Paragraph("SemiBold (600)", td_style), Paragraph("20 pt", td_style), Paragraph("-0.01 em", td_style), Paragraph("Property cards, requirement codes", td_style)],
        [Paragraph("bodyMedium", td_bold_style), Paragraph("14 pt", td_style), Paragraph("Medium (500)", td_style), Paragraph("20 pt", td_style), Paragraph("0.0 em", td_style), Paragraph("Inputs, data table cell text", td_style)],
        [Paragraph("body", td_bold_style), Paragraph("13.5 pt", td_style), Paragraph("Regular (400)", td_style), Paragraph("18 pt", td_style), Paragraph("0.0 em", td_style), Paragraph("Descriptions, remarks, chat", td_style)],
        [Paragraph("captionBold", td_bold_style), Paragraph("12 pt", td_style), Paragraph("SemiBold (600)", td_style), Paragraph("16 pt", td_style), Paragraph("+0.01 em", td_style), Paragraph("Status badges, table headers", td_style)],
        [Paragraph("caption", td_bold_style), Paragraph("11 pt", td_style), Paragraph("Regular (400)", td_style), Paragraph("14 pt", td_style), Paragraph("+0.01 em", td_style), Paragraph("Timestamps, subtitles", td_style)],
        [Paragraph("footnote", td_bold_style), Paragraph("10 pt", td_style), Paragraph("Medium (500)", td_style), Paragraph("12 pt", td_style), Paragraph("+0.02 em", td_style), Paragraph("Unread counts, validation text", td_style)],
    ]
    t_typ = Table(type_pdf_data, colWidths=[75, 45, 75, 55, 55, 205])
    t_typ.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), COLOR_TEAL),
        ('GRID', (0,0), (-1,-1), 0.5, COLOR_BORDER),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, COLOR_BG_LIGHT]),
    ]))
    story.append(t_typ)
    story.append(Spacer(1, 6))

    story.append(Paragraph("2.2 Spacing, Radii, Shadows & Breakpoints", h2_style))
    story.append(Paragraph("• <b>Spacing Scale:</b> xs: 4px | s: 8px | m: 12px | l: 16px | xl: 20px | xxl: 24px | xxxl: 32px | huge: 48px | mega: 64px.", bullet_style))
    story.append(Paragraph("• <b>Corner Radii:</b> xs: 4px | s: 8px (Inputs) | m: 12px (Cards) | l: 16px (Panels) | xl: 20px (Modals) | pill: 999px (Chips).", bullet_style))
    story.append(Paragraph("• <b>Elevation & Shadows:</b> soft: 0px 2px 8px (0.04) | medium: 0px 6px 16px (0.08) | floating: 0px 12px 32px (0.12) | primaryGlow: 0px 4px 14px (0.35).", bullet_style))
    story.append(Paragraph("• <b>Glassmorphism:</b> Navigation & overlays utilize BackdropFilter (sigma 20) with 82% surface opacity fill.", bullet_style))
    story.append(Paragraph("• <b>Breakpoints:</b> Mobile: < 768px | Tablet: 768px – 1023px | Desktop: 1024px – 1439px | Ultrawide: >= 1440px (1440px max width).", bullet_style))

    # ── Section 3: App Shell ─────────────────────────────────────────────────
    story.append(Paragraph("3. GLOBAL APPLICATION SHELL ARCHITECTURE", h1_style))
    story.append(Paragraph("3.1 Resizable Sidebar & Glass Top Bar", h2_style))
    story.append(Paragraph("• <b>Resizable Sidebar (ModernSidebar):</b> 245px default width (resizable to 320px via vertical drag handle; collapses to 70px icon rail). Houses logo brand lockup, 9 core module links with dynamic unread badge counters, and UserProfileCard.", bullet_style))
    story.append(Paragraph("• <b>Glass Modern Top Bar (ModernTopBar):</b> 74px desktop height with 420px debounced omni-search field, Quick Add (+) circular button with glow, Notifications center drawer, Team Messages shortcut (/messages), and Super Admin profile dropdown.", bullet_style))
    story.append(Paragraph("• <b>Mobile Bottom Navigation Bar:</b> On viewports < 768px, persistent 5-tab bottom navigation bar: Dashboard, Properties, Quick Add (+), Leads, Profile.", bullet_style))

    # ── Section 4: RBAC ──────────────────────────────────────────────────────
    story.append(Paragraph("4. ROLE-BASED ACCESS CONTROL (RBAC) & PERMISSION MATRIX", h1_style))
    story.append(Paragraph("PropKart v2.1.1 features an enterprise-grade Permission Matrix Service (PermissionMatrixService) with 40+ granular controllable permissions across 7 categories.", body_style))

    rbac_pdf_data = [
        [Paragraph("Feature / Capability", th_style), Paragraph("Super Admin", th_style), Paragraph("Admin", th_style), Paragraph("Sales", th_style), Paragraph("Telecaller", th_style)],
        [Paragraph("Dashboard, Properties, Leads", td_bold_style), Paragraph("YES", td_style), Paragraph("YES", td_style), Paragraph("YES", td_style), Paragraph("YES", td_style)],
        [Paragraph("Rent vs Re-Sale Switch", td_bold_style), Paragraph("YES", td_style), Paragraph("YES", td_style), Paragraph("YES", td_style), Paragraph("YES", td_style)],
        [Paragraph("Create & Edit Properties", td_bold_style), Paragraph("YES", td_style), Paragraph("YES", td_style), Paragraph("YES", td_style), Paragraph("YES", td_style)],
        [Paragraph("Soft Delete to Recycle Bin", td_bold_style), Paragraph("YES", td_style), Paragraph("YES", td_style), Paragraph("NO", td_style), Paragraph("NO", td_style)],
        [Paragraph("Restore / Permanent Drop", td_bold_style), Paragraph("YES (Full)", td_style), Paragraph("YES (Restore)", td_style), Paragraph("NO", td_style), Paragraph("NO", td_style)],
        [Paragraph("Verify Property (Blue Check)", td_bold_style), Paragraph("YES", td_style), Paragraph("YES", td_style), Paragraph("NO", td_style), Paragraph("NO", td_style)],
        [Paragraph("Export to Excel (.xlsx)", td_bold_style), Paragraph("YES", td_style), Paragraph("YES", td_style), Paragraph("NO", td_style), Paragraph("NO", td_style)],
        [Paragraph("Unmasked Client Phone", td_bold_style), Paragraph("YES", td_style), Paragraph("YES", td_style), Paragraph("YES", td_style), Paragraph("Masked Option", td_style)],
        [Paragraph("Campaign Inbound Inbox", td_bold_style), Paragraph("YES", td_style), Paragraph("YES", td_style), Paragraph("NO", td_style), Paragraph("YES (Intake)", td_style)],
        [Paragraph("Manage Webhook Secrets", td_bold_style), Paragraph("YES", td_style), Paragraph("YES", td_style), Paragraph("NO", td_style), Paragraph("NO", td_style)],
        [Paragraph("1-Click Move to CRM", td_bold_style), Paragraph("YES", td_style), Paragraph("YES", td_style), Paragraph("NO", td_style), Paragraph("YES", td_style)],
        [Paragraph("Executive Reports & BI", td_bold_style), Paragraph("YES", td_style), Paragraph("YES", td_style), Paragraph("NO", td_style), Paragraph("NO", td_style)],
        [Paragraph("Live Permission Matrix", td_bold_style), Paragraph("YES (Exclusive)", td_style), Paragraph("NO", td_style), Paragraph("NO", td_style), Paragraph("NO", td_style)],
    ]
    t_rbac = Table(rbac_pdf_data, colWidths=[150, 90, 90, 80, 100])
    t_rbac.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), COLOR_TEAL),
        ('GRID', (0,0), (-1,-1), 0.5, COLOR_BORDER),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, COLOR_BG_LIGHT]),
    ]))
    story.append(t_rbac)

    # ── Section 5: Screens ───────────────────────────────────────────────────
    story.append(Paragraph("5. COMPLETE SCREEN-BY-SCREEN FUNCTIONAL SPECIFICATIONS", h1_style))
    
    story.append(Paragraph("5.1 Authentication & Gatekeeper Screens", h2_style))
    story.append(Paragraph("• <b>/splash:</b> High-resolution brand mark with pulsating shimmer animation (CRMMotion.nameShimmer). Executes startup Isar sync warmup and validates 9-hour session inactivity timeout.", bullet_style))
    story.append(Paragraph("• <b>/get-started:</b> Apple-style presentation card with 'Sign In to Desk' primary CTA, Terms and Privacy footer.", bullet_style))
    story.append(Paragraph("• <b>/login:</b> Email with regex validation, password visibility toggle, rate-limiting banners, and forgot password link.", bullet_style))
    story.append(Paragraph("• <b>/reset-password:</b> Consumes recovery query tokens (token_hash, code) with live password strength meter.", bullet_style))
    story.append(Paragraph("• <b>/terms-and-conditions & /privacy-policy:</b> Typographic document readers rendering embedded legal markdown.", bullet_style))

    story.append(Paragraph("5.2 Executive Dashboard (/dashboard)", h2_style))
    story.append(Paragraph("• <b>Welcome Header:</b> Time-of-day greeting (Good Morning / Afternoon / Evening) + user full name + formatted date + Rent vs Re-Sale atmosphere switch.", bullet_style))
    story.append(Paragraph("• <b>KPI Metric Cards:</b> 4-column desktop / 2-column mobile grid: Total Listed Inventory (+% growth indicator), Available Units (% of stock), Deals Closed (rented/sold), Active Requirements, Registered Team Roster count.", bullet_style))
    story.append(Paragraph("• <b>Today's Schedule Card:</b> Client appointments agenda with time, property code link, client name, assigned executive, status pill, and WhatsApp action.", bullet_style))
    story.append(Paragraph("• <b>Priority Follow-ups Card:</b> Sub-tabs (Today, Due, Future) with client budget, configuration, and direct phone/WhatsApp shortcuts.", bullet_style))
    story.append(Paragraph("• <b>Analytics Section:</b> Residential vs Commercial inventory mix pie chart + Top Localities ranked bar chart.", bullet_style))
    story.append(Paragraph("• <b>Desk Quick Notes:</b> Scratchpad checklist with optimistic check/uncheck updates for agent reminders.", bullet_style))

    story.append(Paragraph("5.3 Properties Inventory Hub (/properties & /properties/:id)", h2_style))
    story.append(Paragraph("• <b>Atmosphere & Category Strip:</b> Rent vs Re-Sale toggle, Residential vs Commercial tabs, BHK chips (1 BHK, 2 BHK, 3 BHK, 4+ BHK, RK, Plot, Office, Shop).", bullet_style))
    story.append(Paragraph("• <b>Desk Toolstrip:</b> Omni-search, Locality multi-select, Price range sliders (₹ Lacs / ₹ Crores), Image status filter (With Images, No Images), 'My Added Only' toggle, Card Grid vs Data Table switcher, Compare checkboxes.", bullet_style))
    story.append(Paragraph("• <b>Property Card Anatomy:</b> Thumbnail carousel with counter (1/8), formatted price header, size badge (Super Built-up & Carpet), Verified Blue Badge, property code, owner WhatsApp contact row, action menu (Edit, Share, Delete).", bullet_style))
    story.append(Paragraph("• <b>Side-by-Side Comparison Modal:</b> Evaluates up to 4 properties across 15 structured parameters (Price, Deposit, Carpet, Floor, Age, Facing, Furnishing, Parking, Bathrooms, Balconies, Maintenance).", bullet_style))
    story.append(Paragraph("• <b>Add / Edit Property (AddEditPropertyScreen):</b> 7-section form: 1. Identity, 2. Location & Map Pin Picker (lat/long reverse geocoding), 3. Dimensions, 4. Commercials (1-6 month deposit calculator), 5. Specs & Amenities, 6. Media (compression & Cloudinary upload), 7. Ownership & Remarks. Integrated CRMDraftRepository for autosave restoration.", bullet_style))
    story.append(Paragraph("• <b>Property Detail Screen (/properties/:id):</b> Full-bleed gallery, spec chips, map view, owner quick-action card, client sharing drawer.", bullet_style))

    story.append(Paragraph("5.4 Recycle Bin (/bin)", h2_style))
    story.append(Paragraph("• <b>Soft Delete Vault:</b> Displays deleted property listings and client requirements with deletion timestamp and retention countdown.", bullet_style))
    story.append(Paragraph("• <b>Actions:</b> 1-click Optimistic Restore back to active inventory or Permanent Drop (Super Admin exclusive).", bullet_style))

    story.append(Paragraph("5.5 Leads & Requirements Hub (/requirements)", h2_style))
    story.append(Paragraph("• <b>Main Tabs:</b> Active Leads, Requirements, Scheduled Follow-ups.", bullet_style))
    story.append(Paragraph("• <b>14-Stage Deal Progression Funnel:</b> Tracks leads through 14 standardized states: 1. Lead Created -> 2. Requirement Added -> 3. Requirement Verified -> 4. Matching Started -> 5. Properties Matched -> 6. Properties Shared -> 7. Client Viewed -> 8. Client Interested -> 9. Site Visit Scheduled -> 10. Site Visit Completed -> 11. Negotiation -> 12. Booking Token -> 13. Documentation -> 14. Closed / Won.", bullet_style))
    story.append(Paragraph("• <b>Automated Matchmaking Engine:</b> Evaluates client budget (10% tolerance), localities, BHK, furnishing, and facing against active inventory. Computes Match Readiness Score (Ready, Needs Information, Cannot Match) and Requirement Quality Metric (High, Medium, Low, Poor).", bullet_style))
    story.append(Paragraph("• <b>Client Sharing Suite:</b> Branded PDF Dossier Generator (PropertySharePdf), Public Web Shortlist Link (/share/:sessionId) with view tracker, and pre-templated WhatsApp broadcast.", bullet_style))
    story.append(Paragraph("• <b>Follow-up System:</b> Calendar & clock alarm picker modal. Strictly isolates external followups from internal_crm_remarks audit trail.", bullet_style))

    story.append(Paragraph("5.6 Campaign & Inbound Marketing Ingestion (/campaign)", h2_style))
    story.append(Paragraph("• <b>Dual-Section Isolation:</b> Segregates inbound records into two non-overlapping pipelines: Property Listing Leads vs Requirement Leads.", bullet_style))
    story.append(Paragraph("• <b>Lead Intelligence Engine:</b> Parses raw text responses from Meta custom questions and Google Forms to extract budget, BHK, and localities. Detects duplicate phone numbers across the database.", bullet_style))
    story.append(Paragraph("• <b>Interactive Status Dropdown:</b> Follow-up (opens schedule modal), Interested (green highlight & 1-click Move to CRM), Not Interested (moves to archive tab).", bullet_style))
    story.append(Paragraph("• <b>1-Click 'Move to CRM':</b> Promotes campaign lead into a permanent property or requirement while preserving ad attribution metadata (meta_lead_id, campaign_name).", bullet_style))
    story.append(Paragraph("• <b>Connections Screen (/campaign/connections):</b> Meta Lead Ads webhook setup, Verify Token, Google Sheets sync URL, and JSON payload simulator.", bullet_style))

    story.append(Paragraph("5.7 Internal Team Messenger (/messages)", h2_style))
    story.append(Paragraph("• <b>Layout:</b> Master-detail responsive split layout (Roster list 320px on left, chat thread on right).", bullet_style))
    story.append(Paragraph("• <b>Super Admin Team Grouping:</b> Roster grouped by teams with 'Propkart Admin' pinned first. Super Admins can inspect cross-team threads.", bullet_style))
    story.append(Paragraph("• <b>Roster Filtering:</b> All, Admins, Telecallers, Sales with unread message badges and active status indicators.", bullet_style))
    story.append(Paragraph("• <b>Chat Canvas:</b> Branded chat bubbles, timestamps, delivery checkmarks, and keyboard shortcuts (Enter to send, Shift+Enter for newline).", bullet_style))

    story.append(Paragraph("5.8 Reports & Business Intelligence (/reports)", h2_style))
    story.append(Paragraph("• <b>Global Filter Bar:</b> Date presets (Today, Yesterday, Last 7 Days, This Month, Custom Range, All Time) + Team/Agent dimension filter.", bullet_style))
    story.append(Paragraph("• <b>Overall Business Insight (/reports/leads/overall-business-insight):</b> Executive revenue projections, 14-stage lead conversion funnel, callback velocity metrics, team leaderboard & rankings, and lead source attribution donut chart.", bullet_style))
    story.append(Paragraph("• <b>Export Options:</b> 1-click export of executive dossiers in .xlsx and formatted .pdf.", bullet_style))

    story.append(Paragraph("5.9 Shared Document Libraries (/library)", h2_style))
    story.append(Paragraph("• <b>Rental Library (/rental-library):</b> Lease agreements, tenant/landlord KYC proofs, deposit receipts, utility clearances, inspection media.", bullet_style))
    story.append(Paragraph("• <b>Re-Sale Library (/resale-library):</b> Sale deeds, title clearances, society NOCs, floor plans, tax receipts, loan sanction letters.", bullet_style))
    story.append(Paragraph("• <b>Service Agent Library (/service-agent-library):</b> Contractor agreements, GST certificates, SLAs, and completed work showcases for electricians, plumbers, and cleaning crews.", bullet_style))

    story.append(Paragraph("5.10 Directories & Team Administration", h2_style))
    story.append(Paragraph("• <b>Client Index (/clients):</b> Buyer/tenant directory with Kanban Pipeline vs Data Table switcher.", bullet_style))
    story.append(Paragraph("• <b>Property Owners (/owners):</b> Landlord registry linked to properties owned with rental yield summaries.", bullet_style))
    story.append(Paragraph("• <b>Builders & Developers (/builders):</b> Developer directory with tier ratings, active projects, and POCs.", bullet_style))
    story.append(Paragraph("• <b>Employees & Users (/users):</b> Staff directory, user creation modal, password reset queue tab, and agent activity drawer.", bullet_style))
    story.append(Paragraph("• <b>Settings & Governance (/settings):</b> Profile editor, Theme customizer with 'Make as System Default', Location manager (cities/localities), Super Admin Permission Matrix Card, Security Audit Logs (/settings/audit-logs), and Sync Diagnostics (/settings/sync-debug).", bullet_style))

    # ── Section 6: Directives ────────────────────────────────────────────────
    story.append(Paragraph("6. UI/UX DESIGNER IMPLEMENTATION DIRECTIVES", h1_style))
    story.append(Paragraph("• <b>Auto-Layout Mandatory:</b> Design responsive auto-layout frames in Figma across 390px (Mobile), 834px (Tablet), and 1440px (Desktop). Avoid fixed-width canvases.", bullet_style))
    story.append(Paragraph("• <b>Information Density:</b> Prioritize high data density, clear typography contrast, and compact padding. Avoid oversized empty hero sections.", bullet_style))
    story.append(Paragraph("• <b>Atmosphere Cues:</b> Distinct visual accents for Rental Mode (cool teal) vs Re-Sale Mode (warm terracotta).", bullet_style))
    story.append(Paragraph("• <b>Mandatory 5 States per Screen:</b> 1. Default Loaded, 2. Skeleton Loading (shimmering layout placeholders), 3. Empty State (friendly graphic + CTA), 4. Error State (icon + retry button), 5. Permission Denied (shield icon + admin contact).", bullet_style))

    # ── Section 7: Route Table ───────────────────────────────────────────────
    story.append(Paragraph("7. MASTER ROUTE & PERMISSION INDEX TABLE", h1_style))
    route_pdf_data = [
        [Paragraph("Screen Name", th_style), Paragraph("Route URL", th_style), Paragraph("Allowed Roles", th_style), Paragraph("Primary Layout", th_style)],
        [Paragraph("Splash & Sync", td_bold_style), Paragraph("/splash", td_style), Paragraph("Public / System", td_style), Paragraph("Responsive Fullscreen", td_style)],
        [Paragraph("Get Started", td_bold_style), Paragraph("/get-started", td_style), Paragraph("Unauthenticated", td_style), Paragraph("Centered Card", td_style)],
        [Paragraph("Login Screen", td_bold_style), Paragraph("/login", td_style), Paragraph("Unauthenticated", td_style), Paragraph("Centered Auth Card", td_style)],
        [Paragraph("Dashboard", td_bold_style), Paragraph("/dashboard", td_style), Paragraph("All 4 Roles", td_style), Paragraph("4-Col Grid / Mobile Stack", td_style)],
        [Paragraph("Properties CRM", td_bold_style), Paragraph("/properties", td_style), Paragraph("All 4 Roles", td_style), Paragraph("Data Table & 3-Col Cards", td_style)],
        [Paragraph("Property Detail", td_bold_style), Paragraph("/properties/:id", td_style), Paragraph("All 4 Roles", td_style), Paragraph("Hero Gallery & Split Specs", td_style)],
        [Paragraph("Leads & Matching", td_bold_style), Paragraph("/requirements", td_style), Paragraph("All 4 Roles", td_style), Paragraph("Pipeline Cards & Table", td_style)],
        [Paragraph("Public Share Link", td_bold_style), Paragraph("/share/:sessionId", td_style), Paragraph("Public Client", td_style), Paragraph("Responsive Web Portal", td_style)],
        [Paragraph("Campaign Inbox", td_bold_style), Paragraph("/campaign/leads", td_style), Paragraph("SuperAdmin, Admin, TC", td_style), Paragraph("High-Density Table", td_style)],
        [Paragraph("Campaign Connectors", td_bold_style), Paragraph("/campaign/connections", td_style), Paragraph("SuperAdmin, Admin", td_style), Paragraph("Form & Payload Inspector", td_style)],
        [Paragraph("Team Messenger", td_bold_style), Paragraph("/messages", td_style), Paragraph("All 4 Roles", td_style), Paragraph("Master-Detail Split", td_style)],
        [Paragraph("Overall Business Report", td_bold_style), Paragraph("/reports/leads/overall..", td_style), Paragraph("SuperAdmin, Admin", td_style), Paragraph("Charts & KPI Dossier", td_style)],
        [Paragraph("Document Library", td_bold_style), Paragraph("/library", td_style), Paragraph("All 4 Roles", td_style), Paragraph("Category 3-Card Grid", td_style)],
        [Paragraph("Employees Directory", td_bold_style), Paragraph("/users", td_style), Paragraph("SuperAdmin, Admin", td_style), Paragraph("User Cards & Roster", td_style)],
        [Paragraph("Recycle Bin", td_bold_style), Paragraph("/bin", td_style), Paragraph("SuperAdmin, Admin", td_style), Paragraph("High-Density Table", td_style)],
        [Paragraph("System Settings", td_bold_style), Paragraph("/settings", td_style), Paragraph("All 4 Roles", td_style), Paragraph("Multi-Tab Master Panel", td_style)],
    ]
    t_rt = Table(route_pdf_data, colWidths=[110, 130, 120, 150])
    t_rt.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), COLOR_TEAL),
        ('GRID', (0,0), (-1,-1), 0.5, COLOR_BORDER),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, COLOR_BG_LIGHT]),
    ]))
    story.append(t_rt)

    # ── Section 8: Sign-off ──────────────────────────────────────────────────
    story.append(Spacer(1, 10))
    story.append(Paragraph("8. DOCUMENT APPROVAL & SIGN-OFF", h1_style))
    story.append(Paragraph("This document represents the formal software requirements specification and UI/UX handoff baseline for PropKart v2.1.1.", body_style))
    story.append(Paragraph("• <b>Product Architecture Approval:</b> Lead Systems Architect, NB Property Tech", bullet_style))
    story.append(Paragraph("• <b>UI/UX Design Lead Approval:</b> Principal UX Designer, NB Property Tech", bullet_style))
    story.append(Paragraph("• <b>Engineering Review:</b> Lead Flutter Engineer & Core API Team", bullet_style))

    doc.build(story, canvasmaker=NumberedCanvas)
    print("PDF generated successfully at:", PDF_OUTPUT)


# =============================================================================
# MAIN RUNNER
# =============================================================================

if __name__ == "__main__":
    print("=" * 70)
    print("PROPKART v2.1.1 - SRS & UI/UX SPECIFICATION GENERATOR")
    print("=" * 70)
    build_docx_document()
    build_pdf_document()
    print("=" * 70)
    print("All documents generated successfully:")
    print("1. Word Document:    ", DOCX_OUTPUT)
    print("2. PDF Document:     ", PDF_OUTPUT)
    print("=" * 70)
