% This is the code of the paper "A True Global Contrast Method for IR Small
% Target Detection under Complex Background", authored by Jinhui Han, Saed
% Moradi, Bo Zhou, Wei Wang, Qian Zhao and Zhen Luo, printed in IEEE TGRS,
% vol. xx, pp. xx, 2025.
clear all
close all
clc
DEBUG=1;

%% read image and show it
IMG_org=imread('./data/400.bmp');
IMG_org=double(rgb2gray(IMG_org));
IMG_org = mat2gray(IMG_org);
[M_org N_org]=size(IMG_org);
if DEBUG==1
    IMG_show=IMG_org;
    figure;
    imshow(IMG_show,[min(min(IMG_show)) max(max(IMG_show))]);
    title('IMG ORG')
end

%% set parameters used in IPI model
lambda=1/sqrt(max(N_org,M_org));
mu=10*lambda;
tol=1e-6;
max_iter = 1000;

opt.dw = 50;
opt.dh = 50;
opt.x_step = 10;
opt.y_step = 10;

x_start=1;
x_end=M_org-mod(M_org,opt.x_step);
y_start=1;
y_end=N_org-mod(N_org,opt.y_step);

kesi=0.1;
dilar=1;

%% Gaussian filtering
GAUS=[1 2 1; 2 4 2; 1 2 1]./16;
IMG_GAUS=zeros(M_org,N_org);
for i=2:1:M_org-1
    for j=2:1:N_org-1
        IMG_GAUS(i,j)=sum(sum(IMG_org(i-1:i+1,j-1:j+1).*GAUS));
    end
end
if DEBUG==1
    IMG_show=IMG_GAUS;
    figure;
    imshow(IMG_show,[min(min(IMG_show)) max(max(IMG_show))]);
    title('IMG GAUS')
end
% save image
IMG_sav=double(IMG_GAUS);
[MX,NX]=size(IMG_sav);
max1=max(max(IMG_sav));
min1=min(min(IMG_sav));
for i=1:1:MX
    for j=1:1:NX
        IMG_sav(i,j)=(round((IMG_sav(i,j)-min1)./(max1-min1).*255));
    end
end
IMG_sav=uint8(IMG_sav);
imwrite(IMG_sav,'./results/IMG_GAUS.tif','tiff');

%% Sparse and low rank decomposition using IPI algorithm
[IMG_L, IMG_S] = winRPCA_median(IMG_org, opt, mu, tol, max_iter);

if DEBUG==1
    IMG_show=IMG_L;
    figure;
    imshow(IMG_show,[min(min(IMG_show)) max(max(IMG_show))]);
    title('IMG L')
    IMG_show=IMG_S;
    figure;
    imshow(IMG_show,[min(min(IMG_show)) max(max(IMG_show))]);
    title('IMG S')
end
%% LMD for low rank part
IMG_L=max(0,IMG_L);
IMG_L_MAXDILA=IMG_L;
for i=dilar+1:1:M_org-dilar
    for j=dilar+1:1:N_org-dilar
        dilatmp=IMG_L(i-dilar:i+dilar,j-dilar:j+dilar);
        IMG_L_MAXDILA(i,j)=max(max(dilatmp));
    end
end
% show image
if DEBUG==1
    IMG_show=IMG_L_MAXDILA;
    figure;
    imshow(IMG_show,[min(min(IMG_show)) max(max(IMG_show))]);
    title('IMG L MAXDILA')    
end
% save image
IMG_sav=double(IMG_S);
[MX,NX]=size(IMG_sav);
max1=max(max(IMG_sav));
min1=min(min(IMG_sav));
for i=1:1:MX
    for j=1:1:NX
        IMG_sav(i,j)=(round((IMG_sav(i,j)-min1)./(max1-min1).*255));
    end
end
IMG_sav=uint8(IMG_sav);
imwrite(IMG_sav,'./results/IMG_T.tif','tiff');

IMG_sav=double(IMG_L);
[MX,NX]=size(IMG_sav);
max1=max(max(IMG_sav));
min1=min(min(IMG_sav));
for i=1:1:MX
    for j=1:1:NX
        IMG_sav(i,j)=(round((IMG_sav(i,j)-min1)./(max1-min1).*255));
    end
end
IMG_sav=uint8(IMG_sav);
imwrite(IMG_sav,'./results/IMG_B.tif','tiff');

IMG_sav=double(IMG_L_MAXDILA);
[MX,NX]=size(IMG_sav);
max1=max(max(IMG_sav));
min1=min(min(IMG_sav));
for i=1:1:MX
    for j=1:1:NX
        IMG_sav(i,j)=(round((IMG_sav(i,j)-min1)./(max1-min1).*255));
    end
end
IMG_sav=uint8(IMG_sav);
imwrite(IMG_sav,'./results/IMG_BLMD.tif','tiff');

%% TGCM calculation
TGCM=IMG_org;
for i=1:1:M_org
    for j=1:1:N_org
        TGCM(i,j)=max(1,IMG_GAUS(i,j)./max(kesi,IMG_L_MAXDILA(i,j))).*max(0,(IMG_GAUS(i,j)-IMG_L_MAXDILA(i,j)));
    end
end
% cut edge
TGCM_CUT=TGCM(x_start:x_end,y_start:y_end);

%% Weighting
IMG_S_NONNG=max(0,IMG_S);
TGCM=mat2gray(TGCM);
IMG_S_NONNG=mat2gray(IMG_S_NONNG);
TGCM_WEIGHT=TGCM.*IMG_S_NONNG;
% cut edge
TGCM_WEIGHT_CUT=TGCM_WEIGHT(x_start:x_end,y_start:y_end);
% show image
if DEBUG==1
    IMG_show=TGCM_CUT;
    figure;
    imshow(IMG_show,[min(min(IMG_show)) max(max(IMG_show))]);
    title('TGCM CUT')
    figure;
    mesh(IMG_show)
    saveas(gcf,'TGCM CUT 3D.tif','tiff');
end
if DEBUG==1
    IMG_show=TGCM_WEIGHT_CUT;
    figure;
    imshow(IMG_show,[min(min(IMG_show)) max(max(IMG_show))]);
    title('TGCM WEIGHT CUT')
    figure;
    mesh(IMG_show)
    saveas(gcf,'TGCM WEIGHT CUT 3D.tif','tiff');
end
% save image
IMG_sav=double(TGCM_CUT);
[MX,NX]=size(IMG_sav);
max1=max(max(IMG_sav));
min1=min(min(IMG_sav));
for i=1:1:MX
    for j=1:1:NX
        IMG_sav(i,j)=(round((IMG_sav(i,j)-min1)./(max1-min1).*255));
    end
end
IMG_sav=uint8(IMG_sav);
imwrite(IMG_sav,'./results/TGCM_CUT.tif','tiff');

IMG_sav=double(TGCM_WEIGHT_CUT);
[MX,NX]=size(IMG_sav);
max1=max(max(IMG_sav));
min1=min(min(IMG_sav));
for i=1:1:MX
    for j=1:1:NX
        IMG_sav(i,j)=(round((IMG_sav(i,j)-min1)./(max1-min1).*255));
    end
end
IMG_sav=uint8(IMG_sav);
imwrite(IMG_sav,'./results/TGCM_WEIGHT_CUT.tif','tiff');
