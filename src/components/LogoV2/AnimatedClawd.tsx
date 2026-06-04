import * as React from 'react';
import { XcoderLogo } from './Clawd.js';

/**
 * Xcoder logo - static ASCII art, no animations.
 * Identical to <XcoderLogo /> but kept for API compatibility.
 */
export function AnimatedClawd(): React.ReactNode {
  return <XcoderLogo />;
}
