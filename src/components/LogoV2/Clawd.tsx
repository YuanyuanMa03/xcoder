import * as React from 'react';
import { Box, Text } from '@anthropic/ink';
import { env } from '../../utils/env.js';

export type XcoderLogoPose = 'default' | 'arms-up' | 'look-left' | 'look-right';

type Props = {
  pose?: XcoderLogoPose;
  bodyColor?: string;
};

type Segments = {
  r1L: string;
  r1E: string;
  r1R: string;
  r2L: string;
  r2R: string;
};

const POSES: Record<XcoderLogoPose, Segments> = {
  default: { r1L: ' ▐', r1E: '▛███▜', r1R: '▌ ', r2L: '▐▟', r2R: '▙▌' },
  'look-left': { r1L: ' ▐', r1E: '▟███▟', r1R: '▌ ', r2L: '▐▟', r2R: '▙▌' },
  'look-right': { r1L: ' ▐', r1E: '▙███▙', r1R: '▌ ', r2L: '▐▟', r2R: '▙▌' },
  'arms-up': { r1L: '▗▟', r1E: '▛███▜', r1R: '▙▖', r2L: ' ▜', r2R: '▛ ' },
};

const APPLE_EYES: Record<XcoderLogoPose, string> = {
  default: ' ▗   ▖ ',
  'look-left': ' ▘   ▘ ',
  'look-right': ' ▝   ▝ ',
  'arms-up': ' ▗   ▖ ',
};

export function XcoderLogo({ pose = 'default', bodyColor }: Props = {}): React.ReactNode {
  const bc = (bodyColor || 'xcoder_body') as keyof import('../../utils/theme.js').Theme;

  if (env.terminal === 'Apple_Terminal') {
    return <AppleTerminalXcoderLogo pose={pose} bodyColor={bc} />;
  }

  const p = POSES[pose];
  return (
    <Box flexDirection="column">
      <Text>
        <Text color={bc}>{p.r1L}</Text>
        <Text color={bc} backgroundColor="xcoder_background">
          {p.r1E}
        </Text>
        <Text color={bc}>{p.r1R}</Text>
      </Text>
      <Text>
        <Text color={bc}>{p.r2L}</Text>
        <Text color={bc} backgroundColor="xcoder_background">
          █████
        </Text>
        <Text color={bc}>{p.r2R}</Text>
      </Text>
      <Text color={bc}>
        {'  '}▘▘ ▝▝{'  '}
      </Text>
    </Box>
  );
}

function AppleTerminalXcoderLogo({
  pose,
  bodyColor,
}: {
  pose: XcoderLogoPose;
  bodyColor: keyof import('../../utils/theme.js').Theme;
}): React.ReactNode {
  return (
    <Box flexDirection="column">
      <Text>
        <Text color={bodyColor}>▗</Text>
        <Text color="xcoder_background" backgroundColor={bodyColor}>
          {APPLE_EYES[pose]}
        </Text>
        <Text color={bodyColor}>▖</Text>
      </Text>
      <Text backgroundColor={bodyColor}>{' '.repeat(7)}</Text>
      <Text color={bodyColor}>▘▘ ▝▝</Text>
    </Box>
  );
}

// Backward compatibility aliases
export const Clawd = XcoderLogo;
export type ClawdPose = XcoderLogoPose;
