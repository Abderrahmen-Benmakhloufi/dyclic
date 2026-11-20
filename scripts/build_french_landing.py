import os

def build():
    with open('demo_audio_base64.txt', 'r', encoding='utf-8') as f:
        b64 = f.read().strip()

    html = f'''<!DOCTYPE html>
<html lang="fr" dir="ltr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="AideLecture : Application mobile d’accompagnement bienveillant pour l’apprentissage du français, adaptée aux élèves dyslexiques et au cursus algérien (Primaire, Moyen, Lycée).">
  <title>AideLecture : Assistant Français DYS</title>
  
  <link rel="icon" type="image/x-icon" href="assets/images/logo/AideLecture_Logo_Transparent.ico">
  
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Atkinson+Hyperlegible:ital,wght@0,400;0,700;1,400&family=Lexend:wght@400;500;600;700&display=swap" rel="stylesheet">

  <style>
/* Hallmark: custom | theme: dys-accessible | critique: calm pedagogical landing page with high contrast and dyslexia-friendly typography */

    :root {{
      /* Palette ergonomique bienveillante (calibrée pour les troubles DYS) */
      --color-bg: #F8F7F4;
      --color-surface: #FCFBF9;
      --color-surface-card: #FCFBF9;
      --color-surface-soft: #F0EEE8;
      --color-header-bg: #F8F7F4;
      --color-primary: #6B5B95;
      --color-primary-hover: #58487E;
      --color-primary-active: #473867;
      --color-primary-light: rgba(107, 91, 149, 0.12);
      --color-pill-border: rgba(107, 91, 149, 0.24);
      --color-pill-highlight-border: rgba(46, 125, 50, 0.32);
      --color-secondary: #A8C3B0;
      --color-secondary-dark: #3F704D;
      --color-text-main: #242220;
      --color-text-muted: #57534E;
      --color-text-on-primary: #FAF9F6;
      --color-border: #E4E0D7;
      --color-border-hover: #C5BFB2;
      --color-highlight: #FEF08A;
      --color-highlight-strong: #FDE047;
      --color-highlight-shadow: rgba(36, 34, 32, 0.12);
      --color-success: #2E7D32;
      --color-success-bg: #E8F5E9;
      --color-tag-bg: #EAE6F2;
      --color-download-bg-tint: rgba(107, 91, 149, 0.05);
      --color-heart: #D9534F;
      --color-danger-btn: #C53030;
      --color-danger-btn-hover: #9B2C2C;
      --color-qr-bg: #FCFBF9;
      
      /* Typographie et espacements */
      --font-dys: 'Atkinson Hyperlegible', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      --font-display: 'Lexend', 'Atkinson Hyperlegible', sans-serif;
      
      --radius-sm: 8px;
      --radius-md: 16px;
      --radius-lg: 24px;
      --radius-full: 9999px;

      --shadow-subtle: 0 4px 16px rgba(36, 34, 32, 0.06);
      --shadow-card: 0 8px 24px rgba(107, 91, 149, 0.08);
      --shadow-hover: 0 12px 32px rgba(107, 91, 149, 0.14);

      --max-width: 1160px;
    }}

    * {{
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }}

    html, body {{
      overflow-x: clip;
      background-color: var(--color-bg);
      color: var(--color-text-main);
      font-family: var(--font-dys);
      line-height: 1.65;
      letter-spacing: 0.015em;
      word-spacing: 0.03em;
      -webkit-font-smoothing: antialiased;
    }}

    .container {{
      width: 100%;
      max-width: var(--max-width);
      margin: 0 auto;
      padding: 0 24px;
    }}

    a:focus-visible,
    button:focus-visible {{
      outline: 3px solid var(--color-primary);
      outline-offset: 3px;
    }}

    a:active,
    button:active {{
      transform: scale(0.98);
    }}

    button:disabled,
    a[aria-disabled="true"] {{
      opacity: 0.5;
      cursor: not-allowed;
      pointer-events: none;
    }}

    /* En-tête */
    .site-header {{
      position: sticky;
      top: 0;
      z-index: 100;
      background-color: var(--color-header-bg);
      border-bottom: 1px solid var(--color-border);
      padding: 12px 0;
    }}

    .nav-inner {{
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
    }}

    .brand-link {{
      display: flex;
      align-items: center;
      gap: 16px;
      text-decoration: none;
      color: var(--color-text-main);
    }}

    .brand-logo {{
      width: 72px;
      height: 72px;
      object-fit: contain;
      border-radius: var(--radius-sm);
    }}

    .brand-titles {{
      display: flex;
      flex-direction: column;
    }}

    .brand-name {{
      font-family: var(--font-display);
      font-size: 1.45rem;
      font-weight: 700;
      color: var(--color-primary);
      line-height: 1.2;
    }}

    .brand-subtitle {{
      font-size: 0.92rem;
      color: var(--color-text-muted);
      line-height: 1.2;
    }}

    .nav-controls {{
      display: flex;
      align-items: center;
      gap: 16px;
    }}

    .btn-header-cta {{
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background-color: var(--color-primary);
      color: var(--color-text-on-primary);
      text-decoration: none;
      font-weight: 700;
      font-size: 0.9rem;
      padding: 8px 20px;
      border-radius: var(--radius-full);
      border: 1px solid transparent;
      white-space: nowrap;
      transition: background-color 0.2s ease, transform 0.2s ease;
    }}

    .btn-header-cta:hover {{
      background-color: var(--color-primary-hover);
      transform: translateY(-1px);
    }}

    .btn-header-cta:active {{
      background-color: var(--color-primary-active);
    }}

    /* Section Hero */
    .hero-section {{
      padding: 56px 0 48px;
    }}

    .hero-grid {{
      display: grid;
      grid-template-columns: minmax(0, 1.15fr) minmax(0, 0.85fr);
      gap: 40px;
      align-items: center;
    }}

    .hero-content {{
      display: flex;
      flex-direction: column;
      gap: 20px;
    }}

    .hero-headline {{
      font-family: var(--font-display);
      font-size: 2.4rem;
      font-weight: 700;
      line-height: 1.25;
      color: var(--color-text-main);
      overflow-wrap: break-word;
      min-width: 0;
      text-wrap: balance;
    }}

    .hero-headline span.accent {{
      color: var(--color-primary);
    }}

    .hero-badge-wrap {{
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
    }}

    .pill-badge {{
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 4px 12px;
      border-radius: var(--radius-full);
      font-size: 0.85rem;
      font-weight: 600;
      background-color: var(--color-tag-bg);
      color: var(--color-primary);
      border: 1px solid var(--color-pill-border);
    }}

    .pill-badge.highlight {{
      background-color: var(--color-success-bg);
      color: var(--color-success);
      border-color: var(--color-pill-highlight-border);
    }}

    .hero-sentence {{
      font-size: 1.15rem;
      color: var(--color-text-muted);
      line-height: 1.6;
      max-width: 580px;
    }}

    .hero-actions {{
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: 16px;
      margin-top: 8px;
    }}

    .btn-main-download {{
      display: inline-flex;
      align-items: center;
      gap: 12px;
      background-color: var(--color-primary);
      color: var(--color-text-on-primary);
      text-decoration: none;
      font-size: 1.05rem;
      font-weight: 700;
      padding: 16px 24px;
      border-radius: var(--radius-md);
      box-shadow: var(--shadow-card);
      border: 2px solid transparent;
      white-space: nowrap;
      transition: background-color 0.2s ease, transform 0.2s ease, box-shadow 0.2s ease;
    }}

    .btn-main-download:hover {{
      background-color: var(--color-primary-hover);
      box-shadow: var(--shadow-hover);
    }}

    .btn-main-download:active {{
      background-color: var(--color-primary-active);
    }}

    .btn-main-download svg {{
      width: 24px;
      height: 24px;
      fill: currentColor;
    }}

    .btn-secondary {{
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background-color: transparent;
      color: var(--color-text-main);
      text-decoration: none;
      font-size: 1rem;
      font-weight: 600;
      padding: 12px 20px;
      border-radius: var(--radius-md);
      border: 1px solid var(--color-border);
      white-space: nowrap;
      transition: background-color 0.2s ease, border-color 0.2s ease;
    }}

    .btn-secondary:hover {{
      background-color: var(--color-surface-soft);
      border-color: var(--color-border-hover);
    }}

    .btn-secondary:active {{
      background-color: var(--color-border);
    }}

    .download-meta {{
      display: flex;
      align-items: center;
      gap: 16px;
      font-size: 0.85rem;
      color: var(--color-text-muted);
    }}

    .download-meta span {{
      display: inline-flex;
      align-items: center;
      gap: 8px;
    }}

    /* Carte Simulation Démo Vivante (Hero Right) */
    .hero-visual {{
      position: relative;
    }}

    .interactive-card {{
      background: var(--color-surface);
      border: 1px solid var(--color-border);
      border-radius: var(--radius-lg);
      padding: 24px;
      display: flex;
      flex-direction: column;
      gap: 16px;
    }}

    .demo-header {{
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 1px solid var(--color-border);
      padding-bottom: 12px;
    }}

    .demo-title-group {{
      display: flex;
      align-items: center;
      gap: 12px;
    }}

    .demo-title-group img {{
      width: 48px;
      height: 48px;
      object-fit: contain;
    }}

    .demo-title-group h2 {{
      font-family: var(--font-display);
      font-size: 1.05rem;
      font-weight: 700;
      color: var(--color-text-main);
      text-wrap: balance;
    }}

    .live-pulse-badge {{
      display: inline-flex;
      align-items: center;
      gap: 8px;
      font-size: 0.78rem;
      font-weight: 700;
      color: var(--color-success);
      background: var(--color-success-bg);
      padding: 4px 12px;
      border-radius: var(--radius-full);
    }}

    .pulse-dot {{
      width: 8px;
      height: 8px;
      background: var(--color-success);
      border-radius: 50%;
    }}

    .demo-text-box {{
      background-color: var(--color-bg);
      border: 1px solid var(--color-border);
      border-radius: var(--radius-md);
      padding: 20px;
      font-size: 1.15rem;
      line-height: 1.8;
      min-height: 140px;
    }}

    .demo-word {{
      display: inline;
      padding: 2px 4px;
      border-radius: 4px;
      transition: background-color 0.15s ease, color 0.15s ease;
    }}

    .demo-word.highlighted {{
      background-color: var(--color-highlight-strong);
      color: var(--color-text-main);
      font-weight: 700;
      box-shadow: 0 1px 3px var(--color-highlight-shadow);
    }}

    .demo-controls {{
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 12px;
    }}

    .demo-speak-btn {{
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background-color: var(--color-primary);
      color: var(--color-text-on-primary);
      border: none;
      padding: 8px 16px;
      border-radius: var(--radius-full);
      font-size: 0.92rem;
      font-weight: 700;
      cursor: pointer;
      transition: background-color 0.2s ease;
    }}

    .demo-speak-btn:hover {{
      background-color: var(--color-primary-hover);
    }}

    .demo-speak-btn:active {{
      background-color: var(--color-primary-active);
    }}

    .demo-font-toggle {{
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 0.85rem;
      color: var(--color-text-muted);
    }}

    /* Piliers / Fonctionnalités */
    .features-section {{
      padding: 64px 0;
      background-color: var(--color-surface);
      border-top: 1px solid var(--color-border);
      border-bottom: 1px solid var(--color-border);
    }}

    .section-intro {{
      text-align: center;
      max-width: 680px;
      margin: 0 auto 48px;
    }}

    .section-title {{
      font-family: var(--font-display);
      font-size: 2.1rem;
      font-weight: 700;
      color: var(--color-text-main);
      margin-bottom: 16px;
      line-height: 1.3;
      text-wrap: balance;
    }}

    .section-desc {{
      font-size: 1.05rem;
      color: var(--color-text-muted);
      line-height: 1.6;
    }}

    .features-grid {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
      gap: 24px;
    }}

    .feature-card {{
      background-color: var(--color-bg);
      border: 1px solid var(--color-border);
      border-radius: var(--radius-lg);
      padding: 28px 24px;
      display: flex;
      flex-direction: column;
      gap: 16px;
      transition: transform 0.2s ease, border-color 0.2s ease, box-shadow 0.2s ease;
    }}

    .feature-card:hover {{
      transform: translateY(-4px);
      border-color: var(--color-primary);
      box-shadow: var(--shadow-card);
    }}

    .feature-icon-wrap {{
      width: 56px;
      height: 56px;
      border-radius: var(--radius-md);
      background-color: var(--color-surface);
      border: 1px solid var(--color-border);
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 8px;
    }}

    .feature-icon-wrap img {{
      width: 100%;
      height: 100%;
      object-fit: contain;
    }}

    .feature-name {{
      font-family: var(--font-display);
      font-size: 1.25rem;
      font-weight: 700;
      color: var(--color-text-main);
      line-height: 1.3;
      text-wrap: balance;
    }}

    .feature-badge {{
      display: inline-block;
      align-self: flex-start;
      padding: 4px 12px;
      border-radius: var(--radius-full);
      font-size: 0.8rem;
      font-weight: 600;
      background-color: var(--color-tag-bg);
      color: var(--color-primary);
    }}

    .feature-text {{
      font-size: 0.98rem;
      color: var(--color-text-muted);
      line-height: 1.6;
    }}

    /* Section Niveaux Scolaires */
    .levels-section {{
      padding: 64px 0;
    }}

    .levels-grid {{
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 24px;
    }}

    .level-card {{
      background-color: var(--color-surface);
      border: 1px solid var(--color-border);
      border-radius: var(--radius-lg);
      padding: 28px 24px;
      display: flex;
      flex-direction: column;
      align-items: center;
      text-align: center;
      gap: 16px;
      transition: transform 0.2s ease, border-color 0.2s ease;
    }}

    .level-card:hover {{
      transform: translateY(-4px);
      border-color: var(--color-secondary-dark);
    }}

    .level-avatar {{
      width: 72px;
      height: 72px;
      border-radius: 50%;
      background: var(--color-bg);
      padding: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      border: 1px solid var(--color-border);
    }}

    .level-avatar img {{
      width: 100%;
      height: 100%;
      object-fit: contain;
    }}

    .level-title {{
      font-family: var(--font-display);
      font-size: 1.3rem;
      font-weight: 700;
      color: var(--color-text-main);
      text-wrap: balance;
    }}

    .level-sub {{
      font-size: 0.88rem;
      font-weight: 600;
      color: var(--color-primary);
    }}

    .level-desc {{
      font-size: 0.95rem;
      color: var(--color-text-muted);
      line-height: 1.55;
    }}

    /* Section Téléchargement */
    .download-section {{
      padding: 64px 0 80px;
      background-color: var(--color-download-bg-tint);
    }}

    .download-box {{
      background-color: var(--color-surface);
      border: 2px solid var(--color-primary);
      border-radius: var(--radius-lg);
      padding: 40px 32px;
      display: grid;
      grid-template-columns: minmax(0, 1.2fr) minmax(0, 0.8fr);
      gap: 40px;
      align-items: center;
    }}

    .download-info h2 {{
      font-family: var(--font-display);
      font-size: 2rem;
      font-weight: 700;
      color: var(--color-text-main);
      margin-bottom: 12px;
      line-height: 1.3;
      text-wrap: balance;
    }}

    .download-info p {{
      font-size: 1.05rem;
      color: var(--color-text-muted);
      margin-bottom: 24px;
      line-height: 1.6;
    }}

    .download-buttons-stack {{
      display: flex;
      flex-direction: column;
      gap: 12px;
      max-width: 400px;
    }}

    .btn-big-apk {{
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 12px;
      background-color: var(--color-primary);
      color: var(--color-text-on-primary);
      text-decoration: none;
      padding: 16px 24px;
      font-size: 1.1rem;
      font-weight: 700;
      border-radius: var(--radius-md);
      white-space: nowrap;
      transition: background-color 0.2s ease, transform 0.2s ease;
      box-shadow: var(--shadow-subtle);
    }}

    .btn-big-apk:hover {{
      background-color: var(--color-primary-hover);
    }}

    .btn-big-apk:active {{
      background-color: var(--color-primary-active);
    }}

    .btn-big-apk svg {{
      width: 26px;
      height: 26px;
      fill: currentColor;
    }}

    /* Bloc de téléchargement alternatif / de secours */
    .fallback-download-box {{
      margin-top: 8px;
      padding: 12px 16px;
      background-color: var(--color-bg);
      border: 1px solid var(--color-border);
      border-radius: var(--radius-md);
      display: flex;
      flex-direction: column;
      gap: 8px;
      text-align: left;
    }}

    .fallback-download-text {{
      font-size: 0.84rem;
      color: var(--color-text-muted);
      line-height: 1.4;
    }}

    .btn-fallback-apk {{
      display: inline-flex;
      align-items: center;
      gap: 8px;
      color: var(--color-primary);
      text-decoration: underline;
      font-size: 0.88rem;
      font-weight: 700;
      white-space: nowrap;
      transition: color 0.2s ease;
    }}

    .btn-fallback-apk:hover {{
      color: var(--color-primary-hover);
    }}

    .spec-pills {{
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      margin-top: 16px;
    }}

    .spec-item {{
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background: var(--color-bg);
      border: 1px solid var(--color-border);
      border-radius: var(--radius-full);
      padding: 4px 12px;
      font-size: 0.85rem;
      color: var(--color-text-main);
      font-weight: 500;
    }}

    /* Boîte QR Code */
    .qr-side {{
      background: var(--color-bg);
      border: 1px solid var(--color-border);
      border-radius: var(--radius-md);
      padding: 24px;
      text-align: center;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 12px;
    }}

    .qr-container {{
      background-color: var(--color-qr-bg);
      padding: 12px;
      border-radius: var(--radius-sm);
      border: 1px solid var(--color-border);
      width: 140px;
      height: 140px;
      display: flex;
      align-items: center;
      justify-content: center;
    }}

    .qr-container svg {{
      width: 100%;
      height: 100%;
    }}

    .qr-label {{
      font-size: 0.88rem;
      font-weight: 600;
      color: var(--color-text-main);
    }}

    .qr-sub {{
      font-size: 0.8rem;
      color: var(--color-text-muted);
    }}

    /* Pied de page */
    .site-footer {{
      border-top: 1px solid var(--color-border);
      padding: 36px 0;
      background: var(--color-surface);
      text-align: center;
      font-size: 0.9rem;
      color: var(--color-text-muted);
    }}

    .footer-content {{
      display: flex;
      flex-direction: column;
      gap: 8px;
      align-items: center;
    }}

    .footer-note {{
      max-width: 600px;
      line-height: 1.5;
    }}

    @media (max-width: 900px) {{
      .hero-grid,
      .download-box {{
        grid-template-columns: minmax(0, 1fr);
        gap: 32px;
      }}

      .levels-grid {{
        grid-template-columns: minmax(0, 1fr);
      }}

      .hero-headline {{
        font-size: 2rem;
      }}
    }}

    @media (max-width: 600px) {{
      .brand-logo {{
        width: 56px;
        height: 56px;
      }}

      .hero-headline {{
        font-size: 1.7rem;
      }}

      .brand-subtitle {{
        display: none;
      }}

      .btn-header-cta {{
        display: none;
      }}

      .download-box {{
        padding: 24px 20px;
      }}
    }}

    @media (prefers-reduced-motion: reduce) {{
      *,
      *::before,
      *::after {{
        animation-duration: 0.01ms !important;
        animation-iteration-count: 1 !important;
        transition-duration: 0.01ms !important;
        scroll-behavior: auto !important;
      }}
    }}
  </style>
</head>
<body>

  <!-- En-tête Navigation -->
  <header class="site-header">
    <div class="container nav-inner">
      <a href="#accueil" class="brand-link" aria-label="Accueil : AideLecture">
        <img src="assets/images/logo/AideLecture_Logo_Purple_Transparent.png" alt="Logo AideLecture" class="brand-logo" width="72" height="72">
        <div class="brand-titles">
          <span class="brand-name">AideLecture</span>
          <span class="brand-subtitle">Assistant Pédagogique DYS et Français</span>
        </div>
      </a>

      <div class="nav-controls">
        <a href="#telecharger" class="btn-header-cta">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
          <span>Télécharger l’APK</span>
        </a>
      </div>
    </div>
  </header>

  <!-- Section Hero -->
  <section class="hero-section" id="accueil">
    <div class="container hero-grid">
      
      <!-- Contenu Hero Gauche -->
      <div class="hero-content">
        <h1 class="hero-headline" id="mainHeadline">
          <span>L’assistant bienveillant pour </span>
          <span class="accent">lire, comprendre et rédiger.</span>
        </h1>

        <div class="hero-badge-wrap">
          <span class="pill-badge">Primaire, Moyen, Lycée</span>
          <span class="pill-badge highlight">Adapté aux besoins DYS</span>
        </div>

        <p class="hero-sentence" id="mainSubsentence">
          L’outil pédagogique adapté aux élèves pour progresser sereinement en français.
        </p>

        <div class="hero-actions">
          <a href="AideLecture.apk" class="btn-main-download" download>
            <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M17.523 15.3414c-.5511 0-.9993-.4486-.9993-.9997s.4482-.9993.9993-.9993c.551 0 .9993.4482.9993.9993.0001.5511-.4483.9997-.9993.9997m-11.046 0c-.5511 0-.9993-.4486-.9993-.9997s.4482-.9993.9993-.9993c.5511 0 .9994.4482.9994.9993 0 .5511-.4483.9997-.9994.9997m11.4045-6.02l1.9973-3.4592a.416.416 0 00-.1521-.5676.416.416 0 00-.5676.1521l-2.0223 3.503C15.5902 8.411 13.856 8.125 12 8.125c-1.8561 0-3.5903.286-5.1369.8247L4.8408 5.4467a.4161.4161 0 00-.5677-.1521.4157.4157 0 00-.1521.5676l1.9973 3.4592C2.6889 11.1867.3432 14.6589 0 18.75h24c-.3432-4.0911-2.6889-7.5633-6.1185-9.4286"/></svg>
            <div>
              <div>Télécharger l’APK</div>
              <div style="font-size:0.75rem; font-weight:400; opacity:0.9;">Version recommandée</div>
            </div>
          </a>

          <a href="#telecharger" class="btn-secondary">
            <span>Options de téléchargement</span>
          </a>
        </div>

        <div class="download-meta">
          <span><strong>Android 7.0+</strong></span>
          <span><strong>100% Hors-ligne</strong></span>
          <span><strong>Sans publicité</strong></span>
        </div>
      </div>

      <!-- Simulation Interactive en Direct -->
      <div class="hero-visual">
        <div class="interactive-card">
          <div class="demo-header">
            <div class="demo-title-group">
              <img src="assets/images/logo/AideLecture_Logo_Purple_Transparent.png" alt="" width="48" height="48">
              <h2>Suivi de lecture dynamique</h2>
            </div>
            <div class="live-pulse-badge">
              <span class="pulse-dot"></span>
              <span>En direct</span>
            </div>
          </div>

          <p style="font-size: 0.88rem; color: var(--color-text-muted);">
            Le surlignage mot à mot guide le regard sans stress cognitif :
          </p>

          <!-- Zone de lecture synchronisée -->
          <div class="demo-text-box" id="demoTextBox">
            <span class="demo-word" id="w0">Pour</span>
            <span class="demo-word" id="w1">ne</span>
            <span class="demo-word" id="w2">plus</span>
            <span class="demo-word" id="w3">confondre</span>
            <span class="demo-word" id="w4">le</span>
            <span class="demo-word" id="w5">p</span>
            <span class="demo-word" id="w6">et</span>
            <span class="demo-word" id="w7">le</span>
            <span class="demo-word" id="w8">q,</span>
            <span class="demo-word" id="w9">observe</span>
            <span class="demo-word" id="w10">leur</span>
            <span class="demo-word" id="w11">orientation</span>
            <span class="demo-word" id="w12">:</span>
            <span class="demo-word" id="w13">le</span>
            <span class="demo-word" id="w14">p</span>
            <span class="demo-word" id="w15">a</span>
            <span class="demo-word" id="w16">sa</span>
            <span class="demo-word" id="w17">boucle</span>
            <span class="demo-word" id="w18">à</span>
            <span class="demo-word" id="w19">droite,</span>
            <span class="demo-word" id="w20">tandis</span>
            <span class="demo-word" id="w21">que</span>
            <span class="demo-word" id="w22">le</span>
            <span class="demo-word" id="w23">q</span>
            <span class="demo-word" id="w24">a</span>
            <span class="demo-word" id="w25">sa</span>
            <span class="demo-word" id="w26">boucle</span>
            <span class="demo-word" id="w27">à</span>
            <span class="demo-word" id="w28">gauche.</span>
          </div>

          <div class="demo-controls">
            <button type="button" class="demo-speak-btn" id="demoPlayBtn" onclick="toggleDemoSpeech()">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"/></svg>
              <span id="demoPlayLabel">Écouter avec suivi</span>
            </button>

            <div class="demo-font-toggle">
              <span>Voix :</span>
              <strong>Française (Native)</strong>
            </div>
          </div>
        </div>
      </div>

    </div>
  </section>

  <!-- Section Fonctionnalités Clés -->
  <section class="features-section" id="fonctionnalites">
    <div class="container">
      <div class="section-intro">
        <h2 class="section-title">Quatre piliers pensés pour l’élève</h2>
        <p class="section-desc">
          Chaque fonction respecte les normes ergonomiques pour alléger la charge cognitive et encourager l’autonomie.
        </p>
      </div>

      <div class="features-grid">
        
        <!-- Pilier 1 : M'aider à lire -->
        <div class="feature-card">
          <div class="feature-icon-wrap">
            <img src="assets/images/ui/feat_reading.png" alt="M'aider à lire" width="44" height="44">
          </div>
          <h3 class="feature-name">M’aider à lire</h3>
          <span class="feature-badge">Confort visuel</span>
          <p class="feature-text">
            Personnalisation de la police (Atkinson, Lexend), interligne aéré, découpage des syllabes et estompage des lettres muettes pour lire sans fatigue.
          </p>
        </div>

        <!-- Pilier 2 : Écouter le texte (TTS) -->
        <div class="feature-card">
          <div class="feature-icon-wrap">
            <img src="assets/images/ui/feat_tts.png" alt="Écouter le texte" width="44" height="44">
          </div>
          <h3 class="feature-name">Écouter avec suivi</h3>
          <span class="feature-badge">Suivi mot à mot</span>
          <p class="feature-text">
            Synthèse vocale française avec mise en valeur jaune dynamique mot par mot. L’élève suit le fil du texte à son propre rythme.
          </p>
        </div>

        <!-- Pilier 3 : Expliquer la consigne -->
        <div class="feature-card">
          <div class="feature-icon-wrap">
            <img src="assets/images/ui/feat_instructions.png" alt="Expliquer la consigne" width="44" height="44">
          </div>
          <h3 class="feature-name">Expliquer la consigne</h3>
          <span class="feature-badge">Méthode pas-à-pas</span>
          <p class="feature-text">
            Décomposition méthodique des énoncés de devoirs en 4 à 6 étapes concrètes : repérer les verbes d’action, trouver les indices et structurer sa réponse.
          </p>
        </div>

        <!-- Pilier 4 : M'aider à écrire -->
        <div class="feature-card">
          <div class="feature-icon-wrap">
            <img src="assets/images/ui/feat_writing.png" alt="M'aider à écrire" width="44" height="44">
          </div>
          <h3 class="feature-name">M’aider à écrire</h3>
          <span class="feature-badge">Tuteur bienveillant</span>
          <p class="feature-text">
            Accompagnement à la rédaction sans faire le travail à la place de l’élève : amorces de phrases, détection d’erreurs et astuces pour distinguer p et q.
          </p>
        </div>

      </div>
    </div>
  </section>

  <!-- Section Cursus / Niveaux Scolaires -->
  <section class="levels-section">
    <div class="container">
      <div class="section-intro">
        <h2 class="section-title">Adapté aux trois paliers scolaires</h2>
        <p class="section-desc">
          L’application adapte automatiquement son niveau d’explication au palier choisi.
        </p>
      </div>

      <div class="levels-grid">
        
        <!-- Niveau Primaire -->
        <div class="level-card">
          <div class="level-avatar">
            <img src="assets/images/ui/cycle_primaire.png" alt="Primaire" width="56" height="56">
          </div>
          <h3 class="level-title">Primaire</h3>
          <span class="level-sub">École primaire (5e AP)</span>
          <p class="level-desc">
            Phrases très courtes, repères visuels clairs et vocabulaire illustré pour consolider les bases de la lecture.
          </p>
        </div>

        <!-- Niveau Moyen -->
        <div class="level-card">
          <div class="level-avatar">
            <img src="assets/images/ui/cycle_college.png" alt="Moyen" width="56" height="56">
          </div>
          <h3 class="level-title">Moyen</h3>
          <span class="level-sub">Enseignement moyen (BEM / Brevet)</span>
          <p class="level-desc">
            Aide aux situations d’intégration, compréhension méthodique des questions d’examen et enrichissement lexical.
          </p>
        </div>

        <!-- Niveau Lycée -->
        <div class="level-card">
          <div class="level-avatar">
            <img src="assets/images/ui/cycle_lycee.png" alt="Lycée" width="56" height="56">
          </div>
          <h3 class="level-title">Lycée</h3>
          <span class="level-sub">Secondaire (1e AS au BAC)</span>
          <p class="level-desc">
            Analyse de textes argumentatifs denses, rigueur de la structure d’idées et préparation sereine au Baccalauréat.
          </p>
        </div>

      </div>
    </div>
  </section>

  <!-- Section Téléchargement & QR Code -->
  <section class="download-section" id="telecharger">
    <div class="container">
      <div class="download-box">
        
        <!-- Info Téléchargement Gauche -->
        <div class="download-info">
          <h2>Téléchargez l’application mobile</h2>
          <p>
            Un outil complet sans abonnement, utilisable en classe et à la maison.
          </p>

          <div class="download-buttons-stack">
            <!-- Bouton principal : Version recommandée légère -->
            <a href="AideLecture.apk" class="btn-big-apk" download>
              <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M17.523 15.3414c-.5511 0-.9993-.4486-.9993-.9997s.4482-.9993.9993-.9993c.551 0 .9993.4482.9993.9993.0001.5511-.4483.9997-.9993.9997m-11.046 0c-.5511 0-.9993-.4486-.9993-.9997s.4482-.9993.9993-.9993c.5511 0 .9994.4482.9994.9993 0 .5511-.4483.9997-.9994.9997m11.4045-6.02l1.9973-3.4592a.416.416 0 00-.1521-.5676.416.416 0 00-.5676.1521l-2.0223 3.503C15.5902 8.411 13.856 8.125 12 8.125c-1.8561 0-3.5903.286-5.1369.8247L4.8408 5.4467a.4161.4161 0 00-.5677-.1521.4157.4157 0 00-.1521.5676l1.9973 3.4592C2.6889 11.1867.3432 14.6589 0 18.75h24c-.3432-4.0911-2.6889-7.5633-6.1185-9.4286"/></svg>
              <span>Télécharger l’application (APK)</span>
            </a>

            <!-- Bloc alternatif pour la version universelle -->
            <div class="fallback-download-box">
              <span class="fallback-download-text">Si cette version ne s’installe pas sur votre appareil :</span>
              <a href="AideLecture-universel.apk" class="btn-fallback-apk" download>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
                <span>Télécharger la version universelle</span>
              </a>
            </div>
          </div>

          <div class="spec-pills">
            <div class="spec-item">Android 7.0 à 15</div>
            <div class="spec-item">Aucune publicité</div>
            <div class="spec-item">Données protégées</div>
          </div>
        </div>

        <!-- QR Code Droite -->
        <div class="qr-side">
          <div class="qr-container" aria-label="QR Code de téléchargement">
            <svg viewBox="0 0 100 100" fill="var(--color-primary)" aria-hidden="true">
              <rect x="5" y="5" width="28" height="28" rx="4" fill="var(--color-primary)"/>
              <rect x="9" y="9" width="20" height="20" rx="2" fill="var(--color-surface)"/>
              <rect x="13" y="13" width="12" height="12" rx="2" fill="var(--color-primary)"/>

              <rect x="67" y="5" width="28" height="28" rx="4" fill="var(--color-primary)"/>
              <rect x="71" y="9" width="20" height="20" rx="2" fill="var(--color-surface)"/>
              <rect x="75" y="13" width="12" height="12" rx="2" fill="var(--color-primary)"/>

              <rect x="5" y="67" width="28" height="28" rx="4" fill="var(--color-primary)"/>
              <rect x="9" y="71" width="20" height="20" rx="2" fill="var(--color-surface)"/>
              <rect x="13" y="75" width="12" height="12" rx="2" fill="var(--color-primary)"/>

              <rect x="38" y="8" width="8" height="8" rx="2"/>
              <rect x="50" y="8" width="8" height="8" rx="2"/>
              <rect x="38" y="22" width="8" height="8" rx="2"/>
              <rect x="50" y="22" width="8" height="8" rx="2"/>

              <rect x="8" y="38" width="8" height="8" rx="2"/>
              <rect x="22" y="38" width="8" height="8" rx="2"/>
              <rect x="38" y="38" width="8" height="8" rx="2"/>
              <rect x="52" y="38" width="12" height="8" rx="2"/>
              <rect x="70" y="38" width="8" height="8" rx="2"/>
              <rect x="84" y="38" width="8" height="8" rx="2"/>

              <rect x="8" y="50" width="12" height="8" rx="2"/>
              <rect x="26" y="50" width="8" height="8" rx="2"/>
              <rect x="42" y="50" width="14" height="8" rx="2"/>
              <rect x="62" y="50" width="8" height="8" rx="2"/>
              <rect x="78" y="50" width="14" height="8" rx="2"/>

              <rect x="38" y="66" width="8" height="8" rx="2"/>
              <rect x="52" y="66" width="10" height="8" rx="2"/>
              <rect x="68" y="66" width="10" height="8" rx="2"/>
              <rect x="84" y="66" width="8" height="8" rx="2"/>

              <rect x="38" y="78" width="12" height="14" rx="2"/>
              <rect x="56" y="84" width="8" height="8" rx="2"/>
              <rect x="70" y="80" width="12" height="12" rx="2"/>
              <rect x="86" y="78" width="6" height="14" rx="1"/>
            </svg>
          </div>
          <span class="qr-label">Scannez avec votre téléphone</span>
          <span class="qr-sub">Pour installer directement l’APK</span>
        </div>

      </div>
    </div>
  </section>

  <!-- Pied de page -->
  <footer class="site-footer">
    <div class="container footer-content">
      <div style="display:flex; align-items:center; gap:12px;">
        <img src="assets/images/logo/AideLecture_Logo_Purple_Transparent.png" alt="AideLecture" width="56" height="56">
        <strong style="color:var(--color-primary); font-size:1.25rem;">AideLecture</strong>
      </div>
      <p class="footer-note">
        Projet éducatif conçu pour soutenir l’apprentissage du français dans le cursus algérien. Fait avec bienveillance pour l’épanouissement de chaque élève.
      </p>
      <div style="font-size:0.82rem; color:var(--color-text-muted);">
        © 2026 : AideLecture (Tous droits réservés)
      </div>
    </div>
  </footer>

  <script>
    // Audio natif français haute fidélité (aucun recours au moteur TTS anglais de Windows)
    const FRENCH_AUDIO_DATA_URI = "data:audio/mp3;base64,{b64}";
    let audioPlayer = null;
    let isPlaying = false;
    let syncInterval = null;

    // Découpage temporel ultra précis des 29 mots (en secondes)
    const wordTimings = [
      {{ start: 0.00, end: 0.28 }},  // 0: Pour
      {{ start: 0.28, end: 0.48 }},  // 1: ne
      {{ start: 0.48, end: 0.78 }},  // 2: plus
      {{ start: 0.78, end: 1.32 }},  // 3: confondre
      {{ start: 1.32, end: 1.50 }},  // 4: le
      {{ start: 1.50, end: 1.88 }},  // 5: p
      {{ start: 1.88, end: 2.08 }},  // 6: et
      {{ start: 2.08, end: 2.28 }},  // 7: le
      {{ start: 2.28, end: 2.95 }},  // 8: q,
      {{ start: 2.95, end: 3.55 }},  // 9: observe
      {{ start: 3.55, end: 3.82 }},  // 10: leur
      {{ start: 3.82, end: 4.60 }},  // 11: orientation
      {{ start: 4.60, end: 5.02 }},  // 12: :
      {{ start: 5.02, end: 5.24 }},  // 13: le
      {{ start: 5.24, end: 5.68 }},  // 14: p
      {{ start: 5.68, end: 5.88 }},  // 15: a
      {{ start: 5.88, end: 6.10 }},  // 16: sa
      {{ start: 6.10, end: 6.55 }},  // 17: boucle
      {{ start: 6.55, end: 6.78 }},  // 18: à
      {{ start: 6.78, end: 7.42 }},  // 19: droite,
      {{ start: 7.42, end: 7.82 }},  // 20: tandis
      {{ start: 7.82, end: 8.04 }},  // 21: que
      {{ start: 8.04, end: 8.24 }},  // 22: le
      {{ start: 8.24, end: 8.68 }},  // 23: q
      {{ start: 8.68, end: 8.88 }},  // 24: a
      {{ start: 8.88, end: 9.10 }},  // 25: sa
      {{ start: 9.10, end: 9.55 }},  // 26: boucle
      {{ start: 9.55, end: 9.78 }},  // 27: à
      {{ start: 9.78, end: 10.60 }}  // 28: gauche.
    ];

    function initAudio() {{
      if (!audioPlayer) {{
        audioPlayer = new Audio();
        audioPlayer.src = 'demo_french_speech.mp3';
        audioPlayer.onerror = function() {{
          audioPlayer.src = FRENCH_AUDIO_DATA_URI;
        }};
        audioPlayer.onended = function() {{
          stopAudio();
        }};
      }}
      return audioPlayer;
    }}

    function clearHighlights() {{
      for (let i = 0; i < wordTimings.length; i++) {{
        const el = document.getElementById('w' + i);
        if (el) el.classList.remove('highlighted');
      }}
    }}

    function updateHighlight() {{
      if (!isPlaying || !audioPlayer) return;
      
      const t = audioPlayer.currentTime;
      let activeIndex = -1;

      for (let i = 0; i < wordTimings.length; i++) {{
        if (t >= wordTimings[i].start && t <= wordTimings[i].end) {{
          activeIndex = i;
          break;
        }}
      }}

      for (let i = 0; i < wordTimings.length; i++) {{
        const el = document.getElementById('w' + i);
        if (el) {{
          if (i === activeIndex) {{
            el.classList.add('highlighted');
          }} else {{
            el.classList.remove('highlighted');
          }}
        }}
      }}
    }}

    function toggleDemoSpeech() {{
      if (isPlaying) {{
        stopAudio();
      }} else {{
        startAudio();
      }}
    }}

    function startAudio() {{
      const player = initAudio();
      player.currentTime = 0;
      
      player.play().then(() => {{
        isPlaying = true;
        updateUI(true);
        if (syncInterval) clearInterval(syncInterval);
        syncInterval = setInterval(updateHighlight, 30);
      }}).catch(err => {{
        console.warn('Playback error, falling back to data URI:', err);
        player.src = FRENCH_AUDIO_DATA_URI;
        player.play().then(() => {{
          isPlaying = true;
          updateUI(true);
          if (syncInterval) clearInterval(syncInterval);
          syncInterval = setInterval(updateHighlight, 30);
        }});
      }});
    }}

    function stopAudio() {{
      isPlaying = false;
      if (syncInterval) {{
        clearInterval(syncInterval);
        syncInterval = null;
      }}
      if (audioPlayer) {{
        audioPlayer.pause();
        audioPlayer.currentTime = 0;
      }}
      clearHighlights();
      updateUI(false);
    }}

    function updateUI(playing) {{
      const btn = document.getElementById('demoPlayBtn');
      const label = document.getElementById('demoPlayLabel');
      
      if (playing) {{
        label.textContent = 'Arrêter ⏹';
        btn.style.backgroundColor = 'var(--color-danger-btn)';
      }} else {{
        label.textContent = 'Écouter avec suivi';
        btn.style.backgroundColor = 'var(--color-primary)';
      }}
    }}
  </script>
</body>
</html>'''

    # Write to root index.html
    with open('index.html', 'w', encoding='utf-8') as out:
        out.write(html)

    # Write to website/index.html (standalone deployment directory)
    os.makedirs('website', exist_ok=True)
    with open(os.path.join('website', 'index.html'), 'w', encoding='utf-8') as out:
        out.write(html)

    print('index.html & website/index.html successfully written!')

if __name__ == '__main__':
    build()
