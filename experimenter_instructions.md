# Experimenter instructions 

### This document contains all of the necessary steps to administer the full experimental protocol to a subject.

1. Physical Setup
    - Print out the consent form
    - Print out the verbal instructions
    - Turn on the computer 
    - Get the Sound Pressure Level Meter 
    - Ensure the headphones and monitor are connected to the computer

2. Config Setup 
    - Copy the template config files `config_ATA_grant_p1_template.yaml` and `config_ATA_grant_p2_template.yaml` to the folder `tinnitus-reconstruction/code/experiment/configs/ATA_grant/`. 
    - Modify the first two lines of both files to have a unique `experiment_name` and `subject_ID` value compared to other existing config files.
    - Change the filenames to reflect the the `experiment_name` or `subject_ID` but keep the `p1` and `p2` designations.
    - Set the `data_dir` field to the local data storage location.

3. MATLAB setup
    - Make sure the installed tinnitus-reconstruction toolbox is the correct one.
    - If none is installed, take the desired version from GitHub.
    - Open MATLAB
    - Place the SPL meter securely in the headphones close to one ear but not touching
    - Run `play_calibration_sound()`.
    - Make sure the measured decibel value on the SPL meter is above 65dB. If it is not, raise the system volume and try again.
    - Save this value as a variable in MATLAB. For example, `cal_dB = 102.6;`
    - Call `RunAllExp(cal_dB)` and navigate to the just-created `p1` config file for this experiment.
    - Once the first screen loads, the experiment is fully set up.

4. Subject Consent
    - Provide a brief description of the project and its goals:

        > The goal of this project is to improve on the existing methods of determining the sound that you and other people with tinnitus hear.
        We are taking a novel approach that makes very few assumptions about the sound, as everyone's tinnitus presents differently. 
        We hope that we will be able to recreate a more nuanced approximation of your tinnitus by the end of this experiment.
        This is not meant as a treatment for your tinnitus, but to aid in existing treatments, as they will be better informed as to the details of each individual's tinnitus experience.
        Before I explain more about the steps of the experiment, I would like you to read this consent form that details what will be expected of you while you're here.
        Take your time reading it, and if you are okay with continuing, please sign and date the bottom. 

    - Allow the subject to read the consent pages fully in as much time as they require.
    - If the subject chooses to participate after reading the form, ensure both they and you sign and date the form in the appropriate place.

5. Subject Instructions
    - Once the form is signed, tell the subject that you are going to read them the instructions before each stage of the study so that each participant hears the same content.
    - Read the associated instructions aloud before each experiment, ask if they have any questions after.
    - See them into the booth, ensure the monitor is active, that the subject is comfortable, understands the instructions and puts the headphones on, then close the door and take a seat on the bench side.
    
        > This study consists of four separate experiments. I will check in with you after each one. A shortened version of what I am about to read will also be on the screen during each experiment.

        > Importantly, if you would like to stop at any time for any reason, you are welcome to. Just let me know. You can also take a break any time you would like for as long as you would like. If you have any questions during the experiment, I'll be right outside the booth and am happy to answer them for you. 

        > The first experiment is designed to find your hearing threshold. That is the lowest volume you can hear at a given frequency.
        To do this, you will alternate between pressing a button to play the sound and adjusting a volume slider. Once the volume is at a level such that you can just hear the sound, click the "save choice" button. This process will repeat until you have answered twice for all sounds. If at some point you cannot hear the sound and the volume slider is as loud as possible, click the "can't hear" checkbox and choose "save choice".

        > The second experiment is intended to match the volume of the same tones you just heard to the loudness of your tinnitus. The interface will look exactly the same as the first experiment, but instead of moving the slider to where you can just barely hear the sound, you will move it to where the loudness of the tone and your tinnitus are approximately equal. Again, once the volume is at a level matching your tinnitus, click the "save choice" button and if you cannot hear the sound with the volume slider as loud as possible, click the "can't hear" checkbox and choose "save choice". This process will also be repeated twice for each tone.

        > The third experiment seeks to identify the pitch of your tinnitus. Two sounds will play back to back and you will be asked to choose which one was closer to the sound of your tinnitus. This process will continue until the experimental protocol identifies a match. This is a much shorter process than the previous two, so it will be repeated three times.

        > The fourth experiment is different from the previous ones. It is the main part of this study. You will hear a series of noisy sounds, about half of which contain a hidden tinnitus sound. We would like you to answer "yes" to those. Otherwise, answer "no". This section is a lot longer than the previous ones, but you will be presented with a break screen at regular intervals. Once that is completed, I will check in with you and explain the next part that is associated with this experiment.

        > Next, you will see a screen with two sliders, a button to play a sound, and a button to save your choice. Similar to the first two experiments, you will alternate between playing the sound and adjusting the sliders until the sound that is played is as close to your tinnitus as you can make it. Once you are satisfied, click "save choice".
        Finally, you will be asked a few questions to answer on a numerical scale.

END OF INSTRUCTIONS 