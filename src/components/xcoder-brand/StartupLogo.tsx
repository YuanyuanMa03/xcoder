import { Box, Text } from '@anthropic/ink';
import { XcoderLogo } from '../LogoV2/Clawd.js';

const LOGO = [
  '██╗  ██╗ ██████╗ ██████╗ ██████╗ ███████╗██████╗',
  '╚██╗██╔╝██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔══██╗',
  ' ╚███╔╝ ██║     ██║   ██║██║  ██║█████╗  ██████╔╝',
  ' ██╔██╗ ██║     ██║   ██║██║  ██║██╔══╝  ██╔══██╗',
  '██╔╝ ██╗╚██████╗╚██████╔╝██████╔╝███████╗██║  ██║',
  '╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝',
];

export function StartupLogo({ version, mode }: { version: string; mode?: string }) {
  return (
    <Box flexDirection="column" marginBottom={1}>
      <XcoderLogo />
      {LOGO.map((line, i) => (
        <Text key={i} color="#D77757">
          {line}
        </Text>
      ))}
      <Text dimColor> 超越人类与 AI 的边界 · v{version}</Text>
      {mode && mode !== 'default' && <Text dimColor> [{mode}] ❯❯❯</Text>}
    </Box>
  );
}
