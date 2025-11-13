// Compression vidéo pour Flutter Web
// Limite la taille finale à ~2 MB avec qualité acceptable

async function compressVideo(file, maxSizeMB = 2) {
  return new Promise((resolve, reject) => {
    console.log('🎬 Début compression:', file.name, 'Type:', file.type, 'Taille:', (file.size / (1024 * 1024)).toFixed(2), 'MB');

    const videoElement = document.createElement('video');
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');

    let blobUrl = null;
    let mediaRecorder = null;
    let isCompressing = false;

    // Configuration vidéo
    videoElement.preload = 'auto';
    videoElement.muted = true;
    videoElement.playsInline = true;

    // Fonction de nettoyage
    const cleanup = () => {
      console.log('🧹 Nettoyage ressources');
      videoElement.pause();
      videoElement.removeAttribute('src');
      videoElement.load();
      if (blobUrl) {
        URL.revokeObjectURL(blobUrl);
        blobUrl = null;
      }
    };

    // Timeout de sécurité
    const loadTimeout = setTimeout(() => {
      cleanup();
      reject(new Error('Timeout: La vidéo a mis trop de temps à charger (> 30s)'));
    }, 30000);

    videoElement.onloadedmetadata = () => {
      console.log('📹 Métadonnées chargées');
      clearTimeout(loadTimeout);

      // Vérifier que les métadonnées sont valides
      if (!videoElement.duration || videoElement.duration === Infinity || isNaN(videoElement.duration)) {
        cleanup();
        reject(new Error('Durée vidéo invalide'));
        return;
      }

      try {
        const duration = videoElement.duration;
        const originalWidth = videoElement.videoWidth;
        const originalHeight = videoElement.videoHeight;

        // Calculer la résolution optimale pour ~2 MB
        let targetWidth = originalWidth;
        let targetHeight = originalHeight;

        // Réduire la résolution si nécessaire
        const maxDimension = 720; // 720p max
        if (originalWidth > maxDimension || originalHeight > maxDimension) {
          const ratio = originalWidth / originalHeight;
          if (originalWidth > originalHeight) {
            targetWidth = maxDimension;
            targetHeight = Math.round(maxDimension / ratio);
          } else {
            targetHeight = maxDimension;
            targetWidth = Math.round(maxDimension * ratio);
          }
        }

        // S'assurer que les dimensions sont paires (requis pour certains codecs)
        targetWidth = Math.round(targetWidth / 2) * 2;
        targetHeight = Math.round(targetHeight / 2) * 2;

        canvas.width = targetWidth;
        canvas.height = targetHeight;

        // Calculer le bitrate pour atteindre ~2 MB
        const targetSizeBytes = maxSizeMB * 1024 * 1024;
        const targetBitrate = Math.floor((targetSizeBytes * 8) / duration);

        // Limiter le bitrate entre 500 kbps et 2500 kbps
        const bitrate = Math.max(500000, Math.min(2500000, targetBitrate));

        console.log(`🎬 Configuration compression:
          Résolution: ${originalWidth}x${originalHeight} → ${targetWidth}x${targetHeight}
          Durée: ${duration.toFixed(2)}s
          Bitrate: ${(bitrate / 1000).toFixed(0)} kbps
          Taille cible: ${maxSizeMB} MB`);

        // Capturer le flux vidéo du canvas
        const canvasStream = canvas.captureStream(25); // 25 fps
        const videoTrack = canvasStream.getVideoTracks()[0];

        // Capturer le flux audio de la vidéo originale
        const audioStream = videoElement.captureStream();
        const audioTrack = audioStream.getAudioTracks()[0];

        // Combiner video et audio dans un seul stream
        const stream = new MediaStream();
        stream.addTrack(videoTrack);
        if (audioTrack) {
          stream.addTrack(audioTrack);
          console.log('🔊 Piste audio ajoutée au stream');
        } else {
          console.log('⚠️ Aucune piste audio détectée dans la vidéo');
        }

        // Créer MediaRecorder avec video ET audio
        mediaRecorder = new MediaRecorder(stream, {
          mimeType: 'video/webm;codecs=vp8,opus',
          videoBitsPerSecond: bitrate,
        });

        const chunks = [];

        mediaRecorder.ondataavailable = (e) => {
          if (e.data.size > 0) {
            chunks.push(e.data);
          }
        };

        mediaRecorder.onstop = () => {
          console.log('🏁 MediaRecorder arrêté, création du blob');
          isCompressing = false;
          cleanup();

          const blob = new Blob(chunks, { type: 'video/webm' });
          const compressedSizeMB = blob.size / (1024 * 1024);

          console.log(`✅ Compression terminée:
            Taille originale: ${(file.size / (1024 * 1024)).toFixed(2)} MB
            Taille compressée: ${compressedSizeMB.toFixed(2)} MB
            Réduction: ${(((file.size - blob.size) / file.size) * 100).toFixed(1)}%`);

          // Convertir Blob en Uint8List
          const reader = new FileReader();
          reader.onload = () => {
            const arrayBuffer = reader.result;
            const uint8Array = new Uint8Array(arrayBuffer);

            resolve({
              bytes: Array.from(uint8Array),
              fileName: file.name.replace(/\.[^/.]+$/, '.webm'),
              originalSize: file.size,
              compressedSize: blob.size,
              mimeType: 'video/webm',
            });
          };
          reader.onerror = () => {
            reject(new Error('Erreur lecture blob compressé'));
          };
          reader.readAsArrayBuffer(blob);
        };

        mediaRecorder.onerror = (e) => {
          cleanup();
          reject(new Error(`Erreur MediaRecorder: ${e.error}`));
        };

        // Démarrer l'enregistrement
        mediaRecorder.start(100);
        isCompressing = true;

        // Commencer la lecture et le dessin
        videoElement.currentTime = 0;
        videoElement.play().then(() => {
          console.log('▶️ Lecture démarrée');

          // Dessiner les frames sur le canvas
          const drawFrame = () => {
            if (!isCompressing) {
              console.log('⏹️ Compression arrêtée');
              return;
            }

            if (videoElement.ended) {
              console.log('🏁 Vidéo terminée, arrêt enregistrement');
              mediaRecorder.stop();
              return;
            }

            if (videoElement.paused) {
              console.log('⏸️ Vidéo en pause (inattendu)');
              mediaRecorder.stop();
              return;
            }

            // Dessiner la frame actuelle
            ctx.drawImage(videoElement, 0, 0, targetWidth, targetHeight);
            requestAnimationFrame(drawFrame);
          };

          drawFrame();
        }).catch(err => {
          cleanup();
          reject(new Error(`Erreur lecture vidéo: ${err.message}`));
        });

      } catch (error) {
        cleanup();
        reject(error);
      }
    };

    videoElement.onerror = (e) => {
      clearTimeout(loadTimeout);
      cleanup();

      const errorCode = videoElement.error?.code;
      const errorMessage = videoElement.error?.message || 'Erreur inconnue';

      console.error('❌ Erreur vidéo:', e);
      console.error('   Code erreur:', errorCode);
      console.error('   Message:', errorMessage);

      reject(new Error(`Erreur de chargement vidéo (code ${errorCode}): ${errorMessage}`));
    };

    // Créer l'URL et charger la vidéo
    try {
      blobUrl = URL.createObjectURL(file);
      console.log('📎 Blob URL créé:', blobUrl);
      videoElement.src = blobUrl;
      videoElement.load();
    } catch (e) {
      clearTimeout(loadTimeout);
      cleanup();
      reject(new Error(`Erreur création Blob URL: ${e.message}`));
    }
  });
}

// Exposer la fonction pour Dart
window.compressVideoFile = compressVideo;
