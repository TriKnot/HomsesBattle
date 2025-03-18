class UCameraShakeComponent : UActorComponent
{
    float ShakeIntensity = 0.0f;  // Normalized shake intensity (0-1)
    bool bIsShaking = false;

    TArray<int> NoiseSeed;

    float MaxOffset = 1.0f;
    float MaxRotation = 1.0f;
    float IntensityFalloffPerSecond = 1.0f;

    UCameraComponent CameraComponent;
    FVector CameraTotalLocationOffset;
    FRotator CameraTotalRotationOffset;

    void Init(UCameraComponent Camera, float inMaxOffset, float inMaxRotation, float inIntensityFalloff)
    {
        CameraComponent = Camera;
        if (CameraComponent == nullptr) return;
        
        MaxOffset = inMaxOffset;
        MaxRotation = inMaxRotation;
        IntensityFalloffPerSecond = inIntensityFalloff;

        NoiseSeed.SetNum(6);
        UpdateSeeds();
    }

    void AddIntensity(float Intensity)
    {
        ShakeIntensity = Math::Clamp(ShakeIntensity + Intensity, 0.0f, 1.0f); 
        bIsShaking = true;
    }

    void UpdateSeeds()
    {
        int Seed = Math::Rand();
        NoiseSeed[0] = Seed;
        NoiseSeed[1] = Seed + 1;
        NoiseSeed[2] = Seed + 2;
        NoiseSeed[3] = Seed + 3;
        NoiseSeed[4] = Seed + 4;
        NoiseSeed[5] = Seed + 5;
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if (!bIsShaking || CameraComponent == nullptr)
            return;

        // Square intensite for a better feel
        float ShakeAmount = ShakeIntensity * ShakeIntensity;  

        if (ShakeAmount > 0.0f)
        {
            float TimeFactor = System::GameTimeInSeconds;

            float OffsetX = MaxOffset * ShakeAmount * Math::PerlinNoise1D(NoiseSeed[0] * TimeFactor);
            float OffsetY = MaxOffset * ShakeAmount * Math::PerlinNoise1D(NoiseSeed[1] * TimeFactor);
            float OffsetZ = MaxOffset * ShakeAmount * Math::PerlinNoise1D(NoiseSeed[2] * TimeFactor);
            
            float Yaw = MaxRotation * ShakeAmount * Math::PerlinNoise1D(NoiseSeed[3] * TimeFactor);
            float Pitch = MaxRotation * ShakeAmount * Math::PerlinNoise1D(NoiseSeed[4] * TimeFactor);
            float Roll = MaxRotation * ShakeAmount * Math::PerlinNoise1D(NoiseSeed[5] * TimeFactor);

            FVector ShakeOffset = FVector(OffsetX, OffsetY, OffsetZ);
            FRotator ShakeRotation = FRotator(Pitch, Yaw, Roll);

            FVector LocationDiff = CameraTotalLocationOffset - ShakeOffset;
            FRotator RotationDiff = CameraTotalRotationOffset - ShakeRotation;
            
            // Offset by the difference only
            CameraComponent.AddLocalOffset(LocationDiff);
            CameraComponent.AddLocalRotation(RotationDiff);

            CameraTotalLocationOffset = ShakeOffset;
            CameraTotalRotationOffset = ShakeRotation;

            // Reduce intensity over time
            ShakeIntensity -= IntensityFalloffPerSecond * DeltaSeconds;
            ShakeIntensity = Math::Clamp(ShakeIntensity, 0.0f, 1.0f);
        }
        else
        {
            // Reset by Substracting the total offset
            CameraComponent.AddLocalOffset(-CameraTotalLocationOffset);
            CameraComponent.AddLocalRotation(CameraTotalRotationOffset.Inverse);
            bIsShaking = false;
            UpdateSeeds();
        }
    }
}

