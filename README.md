# fig2pov: Convert MATLAB figure to Povray script

```
pp=patch('Vertices',[0 0 0; 0 0 1; 0 1 0; 0 1 1; 1 0 0; 1 0 1; 1 1 0; 1 1 1], ...
	 'Faces',[1 2 4 3; 5 6 8 7; 1 2 6 5; 3 4 8 7; 1 3 7 5; 2 4 8 6], ...
	 'FaceColor', [1 0 0]);
view(3)
axis equal
```
MATLAB will create the following figure:

![matlab cube](cube.png)

Next, call fig2pov to convert this figure into a Povray script (\*.pov extension) and execute the script by calling Povray:
```
fig2pov(gca, 'cube.pov')

povray cube.pov
```
As a result, Povray will generate the following figure:

![povray cube 1](cube_povray1.png)
