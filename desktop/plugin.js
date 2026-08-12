/**
 * Pixel Office — desktop pane.
 *
 * Live agent office: a bottom-docked pane listing every Hermes agent
 * (main + subagents) with a big CRACK THE WHIP button. Data comes from
 * the plugin's own backend namespace (/api/plugins/pixel-office/...),
 * polled every 2.5s via the app's React Query client.
 */

import { cn, haptic, host, Tip, useQuery, useQueryClient } from '@hermes/plugin-sdk'
import { jsx, jsxs } from 'react/jsx-runtime'

const ID = 'pixel-office'

const STATUS_COLORS = {
  working: 'var(--ui-accent)',
  thinking: 'var(--ui-text-secondary)',
  waiting: 'var(--ui-accent)',
  idle: 'var(--ui-text-quaternary)',
  done: 'var(--ui-accent)',
  gone: 'var(--ui-text-quaternary)'
}

function ago(ts) {
  if (!ts) return ''
  const s = Math.max(0, Math.floor(Date.now() / 1000 - ts))
  if (s < 60) return s + 's'
  if (s < 3600) return Math.floor(s / 60) + 'm'
  return Math.floor(s / 3600) + 'h'
}

function AgentCard({ a, now }) {
  const whipped = a.whipped_at && now - a.whipped_at < 15
  return jsxs('div', {
    className: cn(
      'flex flex-col gap-0.5 rounded-md border px-2.5 py-1.5 text-xs',
      'border-(--ui-stroke-secondary) bg-(--chrome-action-hover)',
      whipped && 'border-(--ui-accent)'
    ),
    children: [
      jsxs('div', {
        className: 'flex items-center gap-1.5',
        children: [
          jsx('span', {
            className: 'inline-block h-2 w-2 rounded-full',
            style: { background: STATUS_COLORS[a.status] || STATUS_COLORS.idle }
          }),
          jsx('span', {
            className: 'truncate font-medium text-(--ui-text-primary)',
            title: a.label,
            children: a.label
          }),
          a.kind === 'subagent' &&
            jsx('span', { className: 'text-[10px] uppercase text-(--ui-text-quaternary)', children: 'sub' }),
          jsx('span', {
            className: 'ml-auto text-[10px] uppercase text-(--ui-text-tertiary)',
            children: a.status
          }),
          whipped && jsx('span', { children: '💥' })
        ]
      }),
      a.tool && jsx('div', { className: 'font-mono text-[11px] text-(--ui-text-secondary)', children: a.tool }),
      a.detail && jsx('div', { className: 'truncate text-[11px] text-(--ui-text-quaternary)', children: a.detail })
    ]
  })
}

function OfficePane() {
  const qc = useQueryClient()
  const { data, isError, isLoading } = useQuery({
    queryKey: [ID, 'state'],
    queryFn: async () => {
      const res = await ctxRest('/state', { method: 'GET' })
      return res
    },
    refetchInterval: 2500,
    refetchIntervalInBackground: false
  })

  const agents = (data && data.agents) || []
  const whip = (data && data.whip) || { count: 0, last: null }

  const crack = () => {
    void (async () => {
      haptic('tap')
      try {
        await ctxRest('/whip', { method: 'POST', body: { by: 'desktop pane', target: '' } })
        host.notify({ kind: 'success', message: '💥 CRACK! The whip has been cracked.' })
        qc.invalidateQueries({ queryKey: [ID, 'state'] })
      } catch {
        host.notify({ kind: 'error', message: 'Whip failed — is the office plugin enabled?' })
      }
    })()
  }

  return jsxs('div', {
    className: 'flex h-full flex-col gap-2 overflow-hidden p-2.5',
    children: [
      jsxs('div', {
        className: 'flex items-center gap-2',
        children: [
          jsx('span', { className: 'text-xs font-semibold tracking-wide text-(--ui-text-secondary)', children: 'PIXEL OFFICE' }),
          jsx('span', { className: 'text-[11px] text-(--ui-text-quaternary)', children: agents.length + ' agents · ' + whip.count + ' whips' }),
          jsx('span', { className: 'flex-1' }),
          jsx('button', {
            type: 'button',
            onClick: crack,
            className: cn(
              'rounded-md border border-(--ui-accent) px-2.5 py-0.5 text-[11px] font-bold',
              'text-(--ui-accent) transition-colors hover:bg-(--chrome-action-hover)'
            ),
            children: '🪄 CRACK THE WHIP'
          })
        ]
      }),
      isLoading && jsx('div', { className: 'text-xs text-(--ui-text-quaternary)', children: 'loading office…' }),
      isError && jsx('div', { className: 'text-xs text-(--ui-text-quaternary)', children: 'office unreachable — check the plugin is enabled' }),
      !isLoading && !isError && agents.length === 0 &&
        jsx('div', { className: 'text-xs text-(--ui-text-quaternary)', children: 'no agents in the office yet' }),
      jsx('div', {
        className: 'grid flex-1 grid-cols-2 gap-1.5 overflow-y-auto lg:grid-cols-3',
        children: agents.map(a => jsx(AgentCard, { a, now: (data && data.ts) || Date.now() / 1000 }, a.id))
      }),
      whip.last &&
        jsx('div', {
          className: 'truncate border-t border-(--ui-stroke-secondary) pt-1 text-[11px] text-(--ui-text-tertiary)',
          children: '💥 "' + whip.last.line + '" — ' + whip.last.by + ', ' + ago(whip.last.ts) + ' ago'
        })
    ]
  })
}

// ctx.rest is captured at register-time (see below) — plain closure keeps
// the component signature clean.
let ctxRest = async () => { throw new Error('not registered') }

export default {
  id: ID,
  name: 'Pixel Office',
  register(ctx) {
    ctxRest = (path, opts) => ctx.rest(path, opts)

    ctx.register({
      id: 'pane',
      area: 'panes',
      title: 'Pixel Office',
      data: { placement: 'bottom', dock: { pane: 'workspace', pos: 'bottom' }, height: '220px' },
      render: () => jsx(OfficePane, {})
    })
  }
}
