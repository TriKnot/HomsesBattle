// Rotate a direction vector towards another direction vector by a maximum number of degrees.
mixin FVector RotateDirectionVectorTowards(const FVector& Direction, const FVector& TargetDirection, float MaxDegrees)
{
    float AngleBetweenRadians = Direction.AngularDistance(TargetDirection);
    float AngleBetweenDegrees = Math::RadiansToDegrees(AngleBetweenRadians);

    if (AngleBetweenDegrees < KINDA_SMALL_NUMBER)
        return TargetDirection;

    float RotationAngleDegrees = Math::Min(AngleBetweenDegrees, MaxDegrees);
    FVector RotationAxis = Direction.CrossProduct(TargetDirection).GetSafeNormal();
    FQuat RotationQuat(RotationAxis, Math::DegreesToRadians(RotationAngleDegrees));

    return RotationQuat.RotateVector(Direction).GetSafeNormal();
}