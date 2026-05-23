import 'package:flutter/material.dart';

abstract class BlendTheme {
  // ── Backgrounds ──────────────────────────────────────────────────────────────
  static const bg     = Color(0xFF090705); // landing deep brown-black
  static const bg2    = Color(0xFF0d0b06); // dashboard bg
  static const bg3    = Color(0xFF111009);
  static const bg4    = Color(0xFF1a160a);
  static const surface = Color(0xFF1a160a);

  // ── Accents ──────────────────────────────────────────────────────────────────
  static const gold    = Color(0xFFc8a84b); // landing gold
  static const goldE   = Color(0xFFffcc33); // bright gold / text node
  static const crimson = Color(0xFF7a1515); // deep crimson
  static const verd    = Color(0xFF3a6b5a); // teal-green
  static const parch   = Color(0xFFd4c49a); // parchment

  // ── Node type colors ─────────────────────────────────────────────────────────
  static const floatColor = Color(0xFFff9933); // orange
  static const textColor  = Color(0xFFffcc33); // gold
  static const imageColor = Color(0xFF33ccff); // cyan
  static const audioColor = Color(0xFF33ff99); // lime green

  // ── Text / UI ────────────────────────────────────────────────────────────────
  static const dim     = Color(0xFF6a5836);
  static const body    = Color(0xFFa09070);
  static const bright  = Color(0xFFe0d0a0);
  static const faint   = Color(0xFF2a1e0a);
  static const border  = Color(0xFF2e2208);
  static const border2 = Color(0xFF3a2e12);

  // ── Status colors ────────────────────────────────────────────────────────────
  static const ok  = Color(0xFF33cc66);
  static const err = Color(0xFFcc3333);

  static Color nodeColor(String type) {
    switch (type) {
      case 'float': return floatColor;
      case 'text':  return textColor;
      case 'image': return imageColor;
      case 'audio': return audioColor;
      default:      return gold;
    }
  }

  static String nodeIcon(String type) {
    switch (type) {
      case 'float': return '◈';
      case 'text':  return '⬡';
      case 'image': return '◉';
      case 'audio': return '♫';
      default:      return '◈';
    }
  }
}
