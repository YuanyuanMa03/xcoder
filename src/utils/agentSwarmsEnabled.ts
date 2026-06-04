/**
 * Centralized runtime check for agent teams/teammate features.
 * Disabled in Xcoder — swarm features are not needed.
 */
export function isAgentSwarmsEnabled(): boolean {
  return false
}
