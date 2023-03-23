## MouSee
Graphical user interface GUI to generate visual stimulation protocols of drifting/static gratings using Psychtoolbox and a DAQ (optional) to get the stimulation type and time in a voltage output.

This program uses two screens: one for visual stimulation and one for setting and controlling the visual stimulation protocol.

1. Select the screen for visual stimulation. 
2. Turn on the app switch to initialize the monitor (using Psychtoolbox functions).
3. Set the default screen (white, blue, gray, gratings, etc.).
4. Set the parameters of the gratings: drifting, directions, size, and frequency. 
5. Set if you want a random sequence and if you want sinusoidal gratings. 
6. (Optional) Select an output voltage channel of a NI-DAQ for recording the type and time of the stimulation. 
7. Set the duration of the stimulus, the duration of the interstimulus (as default screen).
8. Set the number of repetitions. 
9. Preview the visual stimulation protocol and the total time on the right panel.
10. Generate the images to present doing click on the button "Generate gratings".
11. Press Run to start the protocol.

You need a NI-DAQ to send an analog output to record the type and time of visual stimulation. Output voltage of 0 V means no visual stimulation (gray screen), different values mean different directions. For example, if you choose 8 different directions (0º, 45º, 90º, 135º, 180º, 225º, 270º and 315º) the output voltage will use 8 different levels of voltage in order to identify them (0.5, 1, 1.5, 2, 2.5, 3, 3.5 and 4 V).


## Citation
If you use **_MouSee_**, please cite our [paper](https://elifesciences.org/articles/64449):
> Pérez-Ortega J, Alejandre-García T, Yuste R. 2021. Long-term stability of cortical ensembles. Elife 10:1–19. doi:10.7554/eLife.64449
