#!/usr/bin/env node
/**
 * Gera versao email-safe da newsletter.
 * - Inline de todo CSS
 * - Remove media queries incompativeis
 * - Ajusta imagens para caminhos absolutos (quando URL base fornecida)
 */
const fs = require('fs');
const path = require('path');
const juice = require('juice');
const cheerio = require('cheerio');

const inputFile = process.argv[2] || path.resolve(__dirname, '../src/edicoes/01/index.html');
const outputFile = process.argv[3] || path.resolve(__dirname, '../dist/email.html');
const baseUrl = process.argv[4] || ''; // URL base para imagens (ex: https://mda.gov.br/newsletter/)

async function buildEmail() {
  if (!fs.existsSync(inputFile)) {
    console.error('Arquivo HTML nao encontrado:', inputFile);
    process.exit(1);
  }

  fs.mkdirSync(path.dirname(outputFile), { recursive: true });

  console.log('📧 Gerando versao email...');
  let html = fs.readFileSync(inputFile, 'utf-8');

  // Inline CSS
  html = juice(html, {
    preserveMediaQueries: true,
    preserveFontFaces: false, // emails nao suportam @font-face bem
    preserveImportant: true,
    removeStyleTags: false,
  });

  // Ajustar com cheerio
  const $ = cheerio.load(html);

  // Adicionar role="presentation" em tabelas (acessibilidade email)
  $('table').attr('role', 'presentation');

  // Se tiver URL base, converter caminhos relativos de imagens
  if (baseUrl) {
    $('img').each((_, img) => {
      const src = $(img).attr('src');
      if (src && !src.startsWith('http') && !src.startsWith('data:')) {
        $(img).attr('src', baseUrl + src);
      }
    });
    console.log('  ✓ URLs de imagens convertidas para absolutas');
  }

  // Garantir alt text em imagens
  $('img').each((_, img) => {
    if (!$(img).attr('alt')) {
      $(img).attr('alt', '');
    }
  });

  const result = $.html();
  fs.writeFileSync(outputFile, result);

  const fileSize = (Buffer.byteLength(result) / 1024).toFixed(1);
  console.log(`  ✓ Email HTML gerado: ${outputFile} (${fileSize}KB)`);
  console.log('✅ Versao email pronta!');
}

buildEmail().catch(err => {
  console.error('Erro ao gerar email:', err);
  process.exit(1);
});
