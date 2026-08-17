QuestieOcto.Scheduler = QuestieOcto.Scheduler or {}
local S = QuestieOcto.Scheduler

S.queue = {}
S.delayed = {}
S.elapsed = 0
S.interval = 0
S.executed = 0

-- Vanilla's frame budget is much smaller than modern WoW's. The old scheduler
-- ran one slice from every active job each frame; during login that could turn
-- many individually-bounded jobs into one large visible stall. Run at most two
-- queued slices per frame and stop after roughly four milliseconds when the
-- client timer has enough resolution to measure it.
S.maxJobsPerFrame = 2
S.maxSecondsPerFrame = 0.004
S.stats = {
  frames=0, maxQueue=0, maxJobsInFrame=0, maxFrameSeconds=0,
  slowestLabel="none", slowestSeconds=0, lastLabel="none"
}

function S:Enqueue(fn, label)
  if not fn then return end
  table.insert(self.queue, { fn=fn, label=label })
  local n=table.getn(self.queue)
  if n>(self.stats.maxQueue or 0) then self.stats.maxQueue=n end
end

function S:After(delay, fn, key)
  if not fn then return end
  if key then
    self.delayed[key] = { remaining=delay or 0, fn=fn }
  else
    table.insert(self.delayed, { remaining=delay or 0, fn=fn })
  end
end

local function RunDelayed(self, delta)
  local remove = {}
  for k,v in pairs(self.delayed) do
    v.remaining = v.remaining - delta
    if v.remaining <= 0 then table.insert(remove, k) end
  end
  -- Delayed callbacks are intentionally left lightweight: most of them only
  -- enqueue a bounded job or trigger a small UI refresh. The queue itself is
  -- the expensive-work boundary and is budgeted below.
  for _,k in pairs(remove) do
    local entry = self.delayed[k]
    self.delayed[k] = nil
    if entry and entry.fn then entry.fn() end
  end
end

function S:Tick()
  local count=table.getn(self.queue)
  if count<=0 then return end

  local start=(GetTime and GetTime()) or 0
  local ran=0
  local limit=math.min(count,self.maxJobsPerFrame or 2)

  while ran<limit do
    local entry=table.remove(self.queue,1)
    if entry and entry.fn then
      local jobStart=(GetTime and GetTime()) or start
      entry.fn()
      local jobEnd=(GetTime and GetTime()) or jobStart
      local elapsed=jobEnd-jobStart
      self.executed=self.executed+1
      ran=ran+1
      self.stats.lastLabel=entry.label or "unlabelled"
      if elapsed>(self.stats.slowestSeconds or 0) then
        self.stats.slowestSeconds=elapsed
        self.stats.slowestLabel=entry.label or "unlabelled"
      end
    end

    if ran>=1 and GetTime and ((GetTime()-start)>=(self.maxSecondsPerFrame or 0.004)) then break end
  end

  local total=(GetTime and (GetTime()-start)) or 0
  self.stats.frames=(self.stats.frames or 0)+1
  if ran>(self.stats.maxJobsInFrame or 0) then self.stats.maxJobsInFrame=ran end
  if total>(self.stats.maxFrameSeconds or 0) then self.stats.maxFrameSeconds=total end
end

local f=CreateFrame("Frame","QuestieOctoSchedulerFrame",UIParent)
f:SetScript("OnUpdate",function()
  local delta=arg1 or 0
  RunDelayed(S,delta)
  S.elapsed=0
  S:Tick()
end)
