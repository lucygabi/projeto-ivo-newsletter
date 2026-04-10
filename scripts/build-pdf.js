#!/usr/bin/env node
/**
 * Gera PDF da newsletter usando Puppeteer.
 * Uso: node scripts/build-pdf.js [caminho-html] [caminho-pdf]
 */
const fs = require('fs');
const path = require('path');
const puppeteer = require('puppeteer');

async function buildPdf() {
  const inputFile = process.argv[2] || path.resolve(__dirname, '../src/edicoes/01/index.html');
  const outputFile = process.argv[3] || path.resolve(__dirname, '../dist/newsletter-territorio-em-foco-01.pdf');

  if (!fs.existsSync(inputFile)) {
    console.error('Arquivo HTML nao encontrado:', inputFile);
    process.exit(1);
  }

  fs.mkdirSync(path.dirname(outputFile), { recursive: true });

  console.log('📄 Gerando PDF...');
  console.log('  Entrada:', inputFile);

  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  const page = await browser.newPage();

  await page.goto(`file://${inputFile}`, {
    waitUntil: 'networkidle0',
    timeout: 30000,
  });

  // Esperar fontes carregarem
  await page.evaluateHandle('document.fonts.ready');

  await page.pdf({
    path: outputFile,
    format: 'A4',
    printBackground: true,
    margin: { top: '0mm', right: '0mm', bottom: '0mm', left: '0mm' },
    preferCSSPageSize: true,
  });

  await browser.close();

  const fileSize = (fs.statSync(outputFile).size / 1024).toFixed(1);
  console.log(`  ✓ PDF gerado: ${outputFile} (${fileSize}KB)`);
  console.log('✅ PDF pronto!');
}

buildPdf().catch(err => {
  console.error('Erro ao gerar PDF:', err);
  process.exit(1);
});
