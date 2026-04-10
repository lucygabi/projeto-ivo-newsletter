#!/usr/bin/env node
/**
 * Otimiza imagens PNG/JPG para reducao de tamanho.
 * Uso: node scripts/optimize-images.js [pasta]
 */
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

const IMAGES_DIR = process.argv[2] || path.resolve(__dirname, '../src/assets/images');
const SUPPORTED = ['.png', '.jpg', '.jpeg', '.webp'];

async function optimizeImages() {
  if (!fs.existsSync(IMAGES_DIR)) {
    console.error('Pasta nao encontrada:', IMAGES_DIR);
    process.exit(1);
  }

  const files = fs.readdirSync(IMAGES_DIR).filter(f =>
    SUPPORTED.includes(path.extname(f).toLowerCase())
  );

  if (files.length === 0) {
    console.log('Nenhuma imagem encontrada em', IMAGES_DIR);
    return;
  }

  console.log(`🖼️  Otimizando ${files.length} imagens...`);
  let totalSaved = 0;

  for (const file of files) {
    const filePath = path.join(IMAGES_DIR, file);
    const originalSize = fs.statSync(filePath).size;
    const ext = path.extname(file).toLowerCase();

    const optimizedDir = path.join(IMAGES_DIR, 'optimized');
    fs.mkdirSync(optimizedDir, { recursive: true });
    const outputPath = path.join(optimizedDir, file);

    let pipeline = sharp(filePath);

    if (ext === '.png') {
      pipeline = pipeline.png({ quality: 85, compressionLevel: 9 });
    } else if (ext === '.jpg' || ext === '.jpeg') {
      pipeline = pipeline.jpeg({ quality: 80, mozjpeg: true });
    } else if (ext === '.webp') {
      pipeline = pipeline.webp({ quality: 80 });
    }

    await pipeline.toFile(outputPath);

    const newSize = fs.statSync(outputPath).size;
    const saved = originalSize - newSize;
    const pct = ((saved / originalSize) * 100).toFixed(1);
    totalSaved += saved;

    console.log(`  ${file}: ${(originalSize/1024).toFixed(1)}KB → ${(newSize/1024).toFixed(1)}KB (-${pct}%)`);
  }

  console.log(`\n✅ Total economizado: ${(totalSaved/1024).toFixed(1)}KB`);
}

optimizeImages().catch(err => {
  console.error('Erro ao otimizar:', err);
  process.exit(1);
});
