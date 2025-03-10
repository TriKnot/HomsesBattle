struct FCooldownTimer
{
    float Duration;
    float TimeRemaining;
    bool bIsStarted;

    FCooldownTimer(float InDuration)
    {
        Duration = InDuration;
        TimeRemaining = 0.0f;
    }

    // Set the duration of the cooldown timer
    void SetDuration(float InDuration)
    {
        Duration = InDuration;
    }

    // Reset the cooldown timer
    void Reset()
    {
        TimeRemaining = Duration;
        bIsStarted = false;
    }

    // Start the cooldown timer
    void Start()
    {
        bIsStarted = true;
    }

    // Tick the cooldown timer
    // DeltaTime: The time elapsed since the last tick
    // Timer only ticks if it has been started
    void Tick(float DeltaTime)
    {
        if (!bIsStarted)
            return;

        TimeRemaining -= DeltaTime;
        if (TimeRemaining <= 0.0f)
        {
            TimeRemaining = 0.0f;
        }
    }

    // Check if the cooldown timer has started
    bool IsStarted() const
    {
        return bIsStarted;
    }

    // Check if the cooldown timer is active
    bool IsActive() const
    {
        return bIsStarted && TimeRemaining > 0.0f;
    }
    
    // Check if the cooldown timer has expired
    bool IsFinished() const
    {
        return TimeRemaining <= 0.0f;
    }
};
