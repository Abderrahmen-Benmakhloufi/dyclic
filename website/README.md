# 🚀 Site Web Vitrine — AideLecture

Ce dossier `website/` contient l'ensemble du site web vitrine, **100% autonome et prêt à être déployé** sur **Netlify**, **Vercel**, **GitHub Pages** ou tout autre hébergeur statique.

---

## 📁 Structure du dossier

```text
website/
├── index.html                  # La page d'accueil complète (HTML5/CSS3/JS)
├── demo_french_speech.mp3      # Audio haute définition de la démonstration française
├── AideLecture.apk             # ⭐️ Version principale recommandée (légère, ~44 Mo)
├── AideLecture-universel.apk   # 📦 Version universelle de secours (tous appareils)
└── assets/
    └── images/
        ├── logo/               # Logos officiels et favicon AideLecture
        └── ui/                 # Illustrations pédagogiques des fonctionnalités
```

---

## 📲 Noms des fichiers APK pour les téléchargements

- **Version principale (recommandée) :** `AideLecture.apk`  
  *C'est le fichier téléchargé par le gros bouton principal.*
- **Version universelle (secours) :** `AideLecture-universel.apk`  
  *C'est le fichier téléchargé par le lien « Si cette version ne s’installe pas sur votre appareil ».*

> Si vous compilez de nouvelles versions de l'application, placez simplement vos fichiers dans ce dossier en respectant exactement ces deux noms.

---

## 🌐 Déploiement en 1 clic

### Sur Netlify :
1. Connectez-vous sur [Netlify Drop](https://app.netlify.com/drop).
2. Glissez-déposez directement le dossier `website/`.
3. Votre site sera en ligne instantanément avec un lien HTTPS gratuit !

### Sur Vercel :
1. Vous pouvez déployer ce dossier directement via la CLI Vercel : `vercel website`
2. Ou lier votre dépôt GitHub en définissant le Root Directory sur `website`.
