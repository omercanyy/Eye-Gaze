clear all
clf('reset');

%cam=webcam();   %create webcam object
%cam.Resolution = '640x480';

count = 0;

right=imread('RIGHT.jpg');
left=imread('LEFT.jpg');
noface=imread('no_face.jpg');
straight=imread('STRAIGHT.jpg');

detector = vision.CascadeObjectDetector(); % Create a detector for face using Viola-Jones
detector1 = vision.CascadeObjectDetector('EyePairSmall'); %create detector for eyepair

while true % Infinite loop to continuously detect the face
    
    %vid=snapshot(cam);  %get a snapshot of webcam
    vid = imread('http://192.168.1.1:8080/shot.jpg');
    drawnow;
    
    img = rgb2gray(vid);    %convert to grayscale
    img = flipud(img); % Flips the image horizontally
    figure(1); hold on;
    %figure(1); imshow(img); hold on;
    
    figure(2); hold on;
    bbox = step(detector, img); % Creating bounding box using detector
    
    
    if ~isempty(bbox)  %if face exists
        fprintf('rank: %d"', rank(bbox));
        for i=1:rank(bbox) %find the biggest face
            
            biggest_box=i;
            
            faceImage = imcrop(img,bbox(biggest_box,:)); % extract the face from the image
            bboxeyes = step(detector1, faceImage); % locations of the eyepair using detector
            figure(1); imshow(img); hold on; % Displays full image
            
            for j=1:size(bbox,1)    %draw all the regions that contain face
                rectangle('position', bbox(j, :), 'lineWidth', 2, 'edgeColor', 'y');
            end
            
            figure(2);subplot(4,rank(bbox),rank(bbox)+biggest_box),imshow(faceImage);     %display face image
            
            if ~ isempty(bboxeyes)  %check it eyepair is available
                
                biggest_box_eyes=1;
                for j=1:rank(bboxeyes) %find the biggest eyepair
                    if bboxeyes(j,3)>bboxeyes(biggest_box_eyes,3)
                        biggest_box_eyes=j;
                    end
                end
                
                bboxeyeshalf=[bboxeyes(biggest_box_eyes,1),bboxeyes(biggest_box_eyes,2),bboxeyes(biggest_box_eyes,3)/3,bboxeyes(biggest_box_eyes,4)];   %resize the eyepair width in half
                
                eyesImage = imcrop(faceImage,bboxeyeshalf(1,:));    %extract the half eyepair from the face image
                eyesImage = imadjust(eyesImage);    %adjust contrast
                
                r = bboxeyeshalf(1,4)/4;
                [centers, radii, metric] = imfindcircles(eyesImage, [floor(r-r/4) floor(r+r/2)], 'ObjectPolarity','dark', 'Sensitivity', 0.93); % Hough Transform
                [M,I] = sort(radii, 'descend');
                
                eyesPositions = centers;
                
                subplot(4,rank(bbox),rank(bbox)*2+biggest_box),imshow(eyesImage); hold on;
                
                viscircles(centers, radii,'EdgeColor','b');
                
                if ~isempty(centers)
                    pupil_x=centers(1);
                    disL=abs(0-pupil_x);    %distance from left edge to center point
                    disR=abs(bboxeyes(1,3)/3-pupil_x);%distance from right edge to center point
                    figure(2); subplot(4,rank(bbox),3*rank(bbox)+biggest_box);
                    if disL>disR+16
                        imshow(right);
                    else if disR>disL
                            imshow(left);
                        else
                            imshow(straight); count=count+1;
                        end
                    end
                    
                end
            end
        end
    else
        figure(2);subplot(4,1,2);
        imshow(noface);
        figure(2);subplot(4,1,3);
        imshow(noface);
        figure(2);subplot(4,1,4);
        imshow(noface);
    end
    set(gca,'XtickLabel',[],'YtickLabel',[]);
    
    hold off;
    fprintf('count: %d\n', count);
end