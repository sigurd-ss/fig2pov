# fig2pov: Convert MATLAB figure to Povray script

```
pp=patch('Vertices',[0 0 0; 0 0 1; 0 1 0; 0 1 1; 1 0 0; 1 0 1; 1 1 0; 1 1 1], ...
	 'Faces',[1 2 4 3; 5 6 8 7; 1 2 6 5; 3 4 8 7; 1 3 7 5; 2 4 8 6], ...
	 'FaceColor', [1 0 0]);
view(3)
axis equal
```
![matlab cube](cube.tif)