#!/usr/bin/env node
/**
 * Build principal — gera versao otimizada da newsletter em dist/
 * Copia HTML + assets, minifica HTML, inline CSS para compatibilidade email.
 */
const fs = require('fs');
const path = require('path');
const juice = require('juice');
const { minify } = require('html-minifier-terser');

const SRC_DIR = path.resolve(__dirname, '../src/edicoes/01');
const DIST_DIR = path.resolve(__dirname, '../dist');
const ASSETS_SRC = path.resolve(__dirname, '../src/assets');
const ASSETS_DIST = path.resolve(DIST_DIR, 'assets');

function copyDirSync(src, dest) {
  fs.mkdirSync(dest, { recursive: true });
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);
    if (entry.isDirectory()) {
      copyDirSync(srcPath, destPath);
    } else {
      fs.copyFileSync(srcPath, destPath);
    }
  }
}

async function build() {
  console.log('🔨 Build newsletter...');

  // Limpar dist
  fs.rmSync(DIST_DIR, { recursive: true, force: true });
  fs.mkdirSync(DIST_DIR, { recursive: true });

  // Copiar assets
  if (fs.existsSync(ASSETS_SRC)) {
    copyDirSync(ASSETS_SRC, ASSETS_DIST);
    console.log('  ✓ Assets copiados');
  }

  // Ler HTML fonte
  const htmlPath = path.join(SRC_DIR, 'index.html');
  if (!fs.existsSync(htmlPath)) {
    console.error('  ✗ Arquivo nao encontrado:', htmlPath);
    process.exit(1);
  }
  let html = fs.readFileSync(htmlPath, 'utf-8');

  // Versao web (minificada, CSS externo mantido)
  const webHtml = await minify(html, {
    collapseWhitespace: true,
    removeComments: true,
    minifyCSS: true,
  });
  fs.writeFileSync(path.join(DIST_DIR, 'index.html'), webHtml);
  console.log('  ✓ HTML web gerado (minificado)');

  // Versao email (CSS inline)
  const emailHtml = juice(html, {
    preserveMediaQueries: true,
    preserveFontFaces: true,
    removeStyleTags: false,
  });
  const emailMinified = await minify(emailHtml, {
    collapseWhitespace: true,
    removeComments: true,
    minifyCSS: true,
  });
  fs.writeFileSync(path.join(DIST_DIR, 'email.html'), emailMinified);
  console.log('  ✓ HTML email gerado (CSS inline)');

  const webSize = (Buffer.byteLength(webHtml) / 1024).toFixed(1);
  const emailSize = (Buffer.byteLength(emailMinified) / 1024).toFixed(1);
  console.log(`\n📊 Tamanhos: web=${webSize}KB | email=${emailSize}KB`);
  console.log('✅ Build completo! Arquivos em dist/');
}

build().catch(err => {
  console.error('Erro no build:', err);
  process.exit(1);
});
