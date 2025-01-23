// Fill out your copyright notice in the Description page of Project Settings.


#include "HomsePlayerCharacter.h"


// Sets default values
AHomsePlayerCharacter::AHomsePlayerCharacter()
{
 	// Set this character to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

}

// Called when the game starts or when spawned
void AHomsePlayerCharacter::BeginPlay()
{
	Super::BeginPlay();
	
}

// Called every frame
void AHomsePlayerCharacter::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

}

// Called to bind functionality to input
void AHomsePlayerCharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);

}

