// class UCameraShakeComponent : UActorComponent
// {
//     float ShakeIntensity = 0.0f;  // Normalized shake intensity (0-1)
//     bool bIsShaking = false;

//     int NoiseSeed;

//     float MaxOffset = 1.0f;
//     float MaxRotation = 1.0f;
//     float IntensityFalloffPerSecond = 1.0f;

//     UCameraComponent CameraComponent;
//     FVector CameraInitialLocation;
//     FRotator CameraInitialRotation;

//     void Init(UCameraComponent Camera, float inMaxOffset, float inMaxRotation, float inIntensityFalloff)
//     {
//         CameraComponent = Camera;
//         if (CameraComponent == nullptr) return;

//         CameraInitialLocation = CameraComponent.GetRelativeLocation();
//         CameraInitialRotation = CameraComponent.GetRelativeRotation();
        
//         MaxOffset = inMaxOffset;
//         MaxRotation = inMaxRotation;
//         IntensityFalloffPerSecond = inIntensityFalloff;

//         NoiseSeed = Math::Rand();
//     }

//     void AddIntensity(float Intensity)
//     {
//         ShakeIntensity = Math::Clamp(ShakeIntensity + Intensity, 0.0f, 1.0f); // Keep between 0-1
//         bIsShaking = true;
//     }

//     UFUNCTION(BlueprintOverride)
//     void Tick(float DeltaSeconds)
//     {
//         if (!bIsShaking || CameraComponent == nullptr)
//             return;

//         float ShakeAmount = ShakeIntensity * ShakeIntensity;  // Directly use the normalized intensity

//         if (ShakeAmount > 0.0f)
//         {
//             float TimeFactor = System::GameTimeInSeconds;

//             float OffsetX = MaxOffset * ShakeAmount * Math::PerlinNoise1D(NoiseSeed * TimeFactor);
//             float OffsetY = MaxOffset * ShakeAmount * Math::PerlinNoise1D((NoiseSeed + 1) * TimeFactor);
//             float OffsetZ = MaxOffset * ShakeAmount * Math::PerlinNoise1D((NoiseSeed + 2) * TimeFactor);
            
//             float Yaw = MaxRotation * ShakeAmount * Math::PerlinNoise1D((NoiseSeed + 3) * TimeFactor);
//             float Pitch = MaxRotation * ShakeAmount * Math::PerlinNoise1D((NoiseSeed + 4) * TimeFactor);
//             float Roll = MaxRotation * ShakeAmount * Math::PerlinNoise1D((NoiseSeed + 5) * TimeFactor);

//             FVector ShakeOffset = FVector(OffsetX, OffsetY, OffsetZ);
//             FRotator ShakeRotation = FRotator(Pitch, Yaw, Roll);
            
//             CameraComponent.SetRelativeLocation(CameraInitialLocation + ShakeOffset);
//             CameraComponent.SetRelativeRotation(CameraInitialRotation + ShakeRotation);

//             // Reduce intensity over time
//             ShakeIntensity -= IntensityFalloffPerSecond * DeltaSeconds;
//             ShakeIntensity = Math::Clamp(ShakeIntensity, 0.0f, 1.0f);
//         }
//         else
//         {
//             // Smoothly return to original position
//             FVector CurrentLocation = CameraComponent.GetRelativeLocation();
//             FRotator CurrentRotation = CameraComponent.GetRelativeRotation();

//             FVector NewLocation = Math::VInterpTo(CurrentLocation, CameraInitialLocation, DeltaSeconds, 5.0f);
//             FRotator NewRotation = Math::RInterpTo(CurrentRotation, CameraInitialRotation, DeltaSeconds, 5.0f);

//             CameraComponent.SetRelativeLocation(NewLocation);
//             CameraComponent.SetRelativeRotation(NewRotation);

//             // Stop shaking when close enough to the original position
//             if (NewLocation.Equals(CameraInitialLocation, 0.01f) && NewRotation.Equals(CameraInitialRotation, 0.01f))
//             {
//                 bIsShaking = false;
//                 CameraComponent.SetRelativeLocation(CameraInitialLocation);
//                 CameraComponent.SetRelativeRotation(CameraInitialRotation);
//             }
//         }
//     }
// }

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

