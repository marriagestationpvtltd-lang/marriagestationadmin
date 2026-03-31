'use strict';

const functions = require('firebase-functions');
const express = require('express');
const cors = require('cors');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();

// Allow cross-origin requests from any origin (the whole point of this proxy).
app.use(cors({ origin: true }));

// Handle CORS pre-flight OPTIONS requests immediately.
app.options('*', cors({ origin: true }));

// Forward every request to the upstream server, preserving method, headers and body.
app.use(
  '/',
  createProxyMiddleware({
    target: 'https://digitallami.com',
    changeOrigin: true,
    followRedirects: true,
    on: {
      error: (err, req, res) => {
        console.error('Proxy error:', err.message);
        res.status(502).json({ error: 'Bad gateway', message: err.message });
      },
    },
  })
);

exports.proxy = functions.https.onRequest(app);
