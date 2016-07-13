//
//  main.m
//  DSToneFileGenerator
//
//  Created by David Swaintek on 7/12/16.
//  Copyright © 2016 David Swaintek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#define SAMPLE_RATE 44100  //Set the sample rate
#define DURATION 5.0   //Set the duration in seconds
#define FILENAME_FORMAT @"%0.3f-square.aif"  //Set file name to square
//#define FILENAME_FORMAT @"%0.3f-saw.aif"   //Set file name to saw
//#define FILENAME_FORMAT @"%0.3f-sin.aif"   //Set file name to sine


int main(int argc, const char * argv[]) {
    if (argc < 2) {
        printf ("Usage: CAToneFileGenerator n\n(where n is tone in Hz");
        return -1;
    } //Setup for command line usage
    
    double hz = atof(argv[1]); //atof is C++ for convert string to double, accepting command line argument setting as
    assert (hz > 0); //Make sure frequency is valid
    NSLog(@"generating tone %f hz tone", hz);
    
    NSString *fileName = [NSString stringWithFormat:FILENAME_FORMAT, hz]; //sets filename
    NSString *filePath = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:fileName]; //creates a filepath with filename
    NSURL *fileURL = [NSURL fileURLWithPath: filePath]; //turns filepath into a URL so it can be used by Core Audio
    NSLog(@"path: %@", fileURL);
    
    //PREPARE THE FORMAT
    AudioStreamBasicDescription asbd; //create new pointer to description
    memset(&asbd, 0, sizeof(asbd)); //zero out... best practice when initializing new ASBD
    asbd.mSampleRate = SAMPLE_RATE; //set sample rate
    asbd.mFormatID = kAudioFormatLinearPCM; //set format as Linear PCM
    asbd.mFormatFlags = kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked; //bit fields use OR operator for flags.. Big Endian for Linear PCM, uses signed integers, and samples use all bits in each byte
    asbd.mChannelsPerFrame = 1; //set to mono
    asbd.mFramesPerPacket = 1; //Not variable bit rate so each packet will have one frame
    asbd.mBitsPerChannel = 16; //Set to 16 bit depth
    asbd.mBytesPerFrame = 2; //2 8 bit bytes = 16 bit depth
    asbd.mBytesPerPacket = 2; //1 frame per packet, 2 bytes per frame
    
    //SET UP FILE
    AudioFileID audioFile; //set AudioFileID... first step before working with audio
    OSStatus audioErr = noErr;
    audioErr = AudioFileCreateWithURL((__bridge CFURLRef)fileURL, //URL as a bridge from C
                                      kAudioFileAIFFType, //Formatting constant
                                      &asbd, //Pointer to ASBD data
                                      kAudioFileFlags_EraseFile, //behavior flag to overwrite any existing file
                                      &audioFile); //pointer to populate
    assert(audioErr == noErr);
    
    //START WRITING SAMPLES
    long maxSampleCount = SAMPLE_RATE * DURATION; //Sets max samples
    long sampleCount = 0; //Counter
    UInt32 bytesToWrite = 2; //Call to write samples requires a pointer
    double wavelengthInSamples = SAMPLE_RATE / hz; //Calculation for wavelength in samples for frequency
    NSLog (@"wavelengthInSamples =  %f", wavelengthInSamples);
    
    while (sampleCount < maxSampleCount) {
        for (int i=0; i<wavelengthInSamples; i++) {
            
            //WRITE A SQUARE WAVE
            SInt16 sample; //create a sample
            if (i < wavelengthInSamples/2) { //first half of wave
                sample = CFSwapInt16HostToBig (SHRT_MAX); //Linear PCM is big endian, SHRT_MAX is the max Int16 in C
            } else { //second half of wave
                sample = CFSwapInt16HostToBig(SHRT_MIN); //SHRT_MIN is min Int16 in C
            }
            audioErr = AudioFileWriteBytes(audioFile, //Where to write
                                           false, //Caching flag
                                           sampleCount*2, //Location in file to start writing sample, 2 bytes per sample
                                           &bytesToWrite, //Number of bytes you're writing
                                           &sample); //Pointer to the bytes to be written
            
            
            /*
            //WRITE A SAW WAVE
            SInt16 sample = CFSwapInt16HostToBig(((i / wavelengthInSamples) * SHRT_MAX * 2) - SHRT_MAX); //creates a saw wave, looks like a forward slash
            audioErr = AudioFileWriteBytes(audioFile, //Where to write
                                           false, //Caching flag
                                           sampleCount*2, //Location in file to start writing sample, 2 bytes per sample
                                           &bytesToWrite, //Number of bytes you're writing
                                           &sample); //Pointer to the bytes to be written
            
            
            
            //WRITE A SINE WAVE
            SInt16 sample = CFSwapInt16HostToBig((SInt16) SHRT_MAX * sin (2 * M_PI *
                                                                          (i/wavelengthInSamples))); //creates a sine wave
            audioErr = AudioFileWriteBytes(audioFile, //Where to write
                                           false, //Caching flag
                                           sampleCount*2, //Location in file to start writing sample, 2 bytes per sample
                                           &bytesToWrite, //Number of bytes you're writing
                                           &sample); //Pointer to the bytes to be written
             */
            
            
            assert (audioErr == noErr);
            sampleCount ++; //increment sample count
        
        }
    }
    audioErr = AudioFileClose(audioFile);
    assert (audioErr == noErr);
    NSLog (@"Wrote %ld samples", sampleCount);
    
    return 0;
}
