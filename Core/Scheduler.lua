QuestieOcto.Scheduler = QuestieOcto.Scheduler or {}
local S = QuestieOcto.Scheduler

-- O(1) FIFO queue. Vanilla's Lua table.remove(t,1) shifts every remaining
-- element and becomes disproportionately expensive when several incremental
-- startup jobs are queued together. Keep a monotonically advancing head/tail
-- instead, then reset the table when drained.
S.queue = {}
S.queueHead = 1
S.queueTail = 0
S.delayed = {}
S.elapsed = 0
S.interval = 0
S.executed = 0

S.maxJobsPerFrame = 2
S.maxSecondsPerFrame = 0.004
S.stats = {
  frames=0, maxQueue=0, maxJobsInFrame=0, maxFrameSeconds=0,
  slowestLabel="none", slowestSeconds=0, lastLabel="none"
}

function S:PendingCount()
  local n=(self.queueTail or 0)-(self.queueHead or 1)+1
  if n<0 then return 0 end
  return n
end

function S:Enqueue(fn, label)
  if not fn then return end
  self.queueTail=(self.queueTail or 0)+1
  self.queue[self.queueTail]={fn=fn,label=label}
  local n=self:PendingCount()
  if n>(self.stats.maxQueue or 0) then self.stats.maxQueue=n end
end

function S:After(delay, fn, key)
  if not fn then return end
  if key then
    self.delayed[key] = { remaining=delay or 0, fn=fn, label=tostring(key) }
  else
    table.insert(self.delayed, { remaining=delay or 0, fn=fn, label="delayed" })
  end
end

local function RunDelayed(self, delta)
  local remove = {}
  for k,v in pairs(self.delayed) do
    v.remaining = v.remaining - delta
    if v.remaining <= 0 then table.insert(remove, k) end
  end

  -- Due timers enter the same bounded FIFO as every other continuation. The
  -- previous scheduler executed every due callback synchronously before its
  -- frame budget even started; a login/reload event burst could therefore put
  -- substantial work back into one frame despite the queue budget.
  for _,k in pairs(remove) do
    local entry = self.delayed[k]
    self.delayed[k] = nil
    if entry and entry.fn then
      self:Enqueue(entry.fn,"timer:"..tostring(entry.label or k))
    end
  end
end

function S:Tick()
  local count=self:PendingCount()
  if count<=0 then return end

  local start=(GetTime and GetTime()) or 0
  local ran=0
  local limit=math.min(count,self.maxJobsPerFrame or 2)

  while ran<limit and self.queueHead<=self.queueTail do
    local index=self.queueHead
    local entry=self.queue[index]
    self.queue[index]=nil
    self.queueHead=index+1

    -- A missing/cancelled slot must never trap the scheduler in a while loop.
    -- Continue advancing the head even if an entry was somehow cleared.
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

  if self.queueHead>self.queueTail then
    self.queue={}
    self.queueHead=1
    self.queueTail=0
  end

  local total=(GetTime and (GetTime()-start)) or 0
  self.stats.frames=(self.stats.frames or 0)+1
  if ran>(self.stats.maxJobsInFrame or 0) then self.stats.maxJobsInFrame=ran end
  if total>(self.stats.maxFrameSeconds or 0) then self.stats.maxFrameSeconds=total end
end

-- Native fullscreen World Map hides UIParent. Keep the logic scheduler under
-- WorldFrame so bounded queued/delayed work continues while full UI panels are shown.
local f=CreateFrame("Frame","QuestieOctoSchedulerFrame",WorldFrame)
f:SetScript("OnUpdate",function()
  local delta=arg1 or 0
  RunDelayed(S,delta)
  S.elapsed=0
  S:Tick()
end)
