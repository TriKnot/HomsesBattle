namespace PortalTransformHelpers
{
    // Transforms a point from the source portal's local space to the destination portal's world space.
    // Applies mirroring on the X and Y axes in the source portal's local space.
    FVector TransformLocalPointToWorldMirrored(const FVector& LocalPointAtSource, const FTransform& DestPortalTransform)
    {
        FVector MirroredLocalPoint = LocalPointAtSource;

        // Mirror X and Y in source portal's local space
        MirroredLocalPoint.X = -LocalPointAtSource.X;
        MirroredLocalPoint.Y = -LocalPointAtSource.Y;

        return DestPortalTransform.TransformPosition(MirroredLocalPoint);
    }

    // Transforms a rotation from the source portal's local space to the destination portal's world space.
    // Applies a 180-degree flip around the specified WorldFlipAxis
    FRotator TransformLocalRotationToWorldFlipped(const FQuat& RelativeRotationAtSource, const FQuat& DestPortalRotation, const FVector& WorldFlipAxis)
    {
        const FQuat FlipQuat = FQuat(WorldFlipAxis, PI);
        const FQuat MirroredRelativeQuat = FlipQuat * RelativeRotationAtSource;
        return (DestPortalRotation * MirroredRelativeQuat).Rotator();
    }

    // Transforms a direction vector, applying a 180-degree flip around the specified WorldFlipAxis.
    FVector TransformLocalVectorToWorldFlipped(const FVector& LocalDirectionAtSource, const FQuat& DestPortalRotation, const FVector& WorldFlipAxis)
    {
        const FQuat FlipQuat = FQuat(WorldFlipAxis, PI);
        const FVector MirroredLocalDirection = FlipQuat.RotateVector(LocalDirectionAtSource);
        return DestPortalRotation.RotateVector(MirroredLocalDirection);
    }

    // Checks if an actor's bounding box intersects a plane defined by PortalPlaneTransform.
    bool IsActorIntersectingPlane(const AActor Actor, const FTransform& PortalPlaneTransform, float BufferDistance)
    {
        if (!IsValid(Actor))
            return false;

        FVector ActorOrigin;
        FVector ActorBoxExtent;
        Actor.GetActorBounds(true, ActorOrigin, ActorBoxExtent); 
        const FBox ActorBounds = FBox(ActorOrigin - ActorBoxExtent, ActorOrigin + ActorBoxExtent);

        const FVector PortalLocation = PortalPlaneTransform.GetLocation();
        const FVector PortalNormal = PortalPlaneTransform.Rotator().ForwardVector;

        // Calculate the 8 corners of the bounding box
        TArray<FVector> Corners;
        Corners.SetNum(8);
        Corners[0] = FVector(ActorBounds.Min.X, ActorBounds.Min.Y, ActorBounds.Min.Z);
        Corners[1] = FVector(ActorBounds.Min.X, ActorBounds.Min.Y, ActorBounds.Max.Z);
        Corners[2] = FVector(ActorBounds.Min.X, ActorBounds.Max.Y, ActorBounds.Min.Z);
        Corners[3] = FVector(ActorBounds.Min.X, ActorBounds.Max.Y, ActorBounds.Max.Z);
        Corners[4] = FVector(ActorBounds.Max.X, ActorBounds.Min.Y, ActorBounds.Min.Z);
        Corners[5] = FVector(ActorBounds.Max.X, ActorBounds.Min.Y, ActorBounds.Max.Z);
        Corners[6] = FVector(ActorBounds.Max.X, ActorBounds.Max.Y, ActorBounds.Min.Z);
        Corners[7] = FVector(ActorBounds.Max.X, ActorBounds.Max.Y, ActorBounds.Max.Z);

        bool bHasPointInFront = false;
        bool bHasPointBehind = false;

        for (const FVector& Corner : Corners)
        {
            const float Distance = (Corner - PortalLocation).DotProduct(PortalNormal);

            if (Distance > -BufferDistance) // In front or within buffer
            {
                bHasPointInFront = true;
            }
            if (Distance < BufferDistance) // Behind or within buffer
            {
                bHasPointBehind = true;
            }

            // If we have points on both sides of the plane, we have an intersection
            if (bHasPointInFront && bHasPointBehind)
            {
                return true;
            }
        }
        return false;
    }
} 

// --- Portal Struct Definitions ---
struct FDuplicateInfo
{
    AActor DuplicateActor = nullptr;
    bool bOriginalWasTeleported = false;
    bool bInTransition = false;
    float TransitionStartTime = 0.0f;
}

struct FProjectedPortalCorners
{
    int Recursion = 0;
    TArray<FVector2D> ProjectedCorners;
}