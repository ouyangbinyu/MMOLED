clear all; close all; clear classes; clc
                                          
sample_number=2000;
sigma=6e-7;
echo_num=128;
expand_num=256;
WJG_order = 0;
k1 = 0;

labels=zeros(sample_number,expand_num,expand_num,1);%标签
inpute=zeros(sample_number,expand_num,expand_num,2);%输入的数据
mask=zeros(sample_number,expand_num,expand_num,1);%  
% file='/data1/csj/data_2000/all_data/';
dirname='C:\Users\xmu\Desktop\mri\data\MMOLED\';
% outputdir = 'C:\Users\csj94\Desktop\new_eeg\1008\';
fid_dir_all=dir([dirname,'SAMPLES*']);       %列出所有文件夹
for loopi = 1:length(fid_dir_all)
    file = [dirname,fid_dir_all(loopi).name,'\'];
    filename_T2= strcat(file,'Team*.T2');%字符串拼接
    temp_T2 = dir(filename_T2);%所有Team*.T2的文件
    k = length(temp_T2);

    filename_re= strcat(file,'tempd_Team*.ccb');
    temp_re= dir(filename_re); 
 
    filename_m0= strcat(file,'Team*.m0');
    temp_m0= dir(filename_m0);
 
    filename_B1= strcat(file,'Team*.B1');
    temp_B1= dir(filename_B1);
% for k = 1:length(temp_B1)
% temp_B1(k).list = str2num(temp_B1(k).name(5:end-3));
% end
%  [~,index] = sortrows([temp_B1.list].'); temp_B1 = temp_B1(index); clear index
 
    for w=1:1:length(temp_T2)
    
    filename = strcat(file,temp_T2(w).name);
    fip_T2=fopen(filename,'rb');
    [Array_2D_T2,num]=fread(fip_T2,inf,'double');    
    data_T2=Array_2D_T2(:,:);
    pic_T2=reshape(data_T2,512,512);
    T2_2D=imresize(pic_T2,[expand_num,expand_num],'bilinear');
    %figure(1);imagesc(T2_2D)
    if echo_num==128 %回波数判断
        rot_T2=flipud(rot90(T2_2D,1));%逆时针旋转90度，再上下翻转
        %figure(2);imagesc(rot_T2)
    else
        rot_T2=fliplr(rot90(T2_2D,1));%逆时针1旋转90度，再左右翻转
    end
    BW1=edge(rot_T2,'canny',0.01);
     figure(400+w),imagesc(BW1);%边缘函数求图像边缘 具体目的还不太明白

    BW1_right=circshift(BW1,[0 1]);%按列向右移1位
    BW1_left=circshift(BW1,[0 -1]);%按列向左移1位
    BW1_up=circshift(BW1,[1 0]);%按行向上移1位
    BW1_down=circshift(BW1,[-1 0]);%按行向下移1位
    BW_all=BW1+BW1_right+BW1_left+BW1_up+BW1_down;
    BW2=im2bw(BW_all,0);%转化为2值矩阵
    BWt2=~BW2;%再取反
    figure(100+w),imagesc(BWt2);
%     mask(w + k1,:,:,1)=BW3;
    %从这里开始读取temp文件的数据
    filename_re = strcat(file,temp_re(w,1).name);
    origin_1D_data=load(filename_re, '-ascii');
    data_size=size(origin_1D_data);
    length1=data_size(1)/echo_num;
    origin_1D_complex=origin_1D_data(:,1)+1.0i*origin_1D_data(:,2);%K空间的实部和虚部组成复数
    origin_2D_complex=(reshape(origin_1D_complex,echo_num,echo_num)).';
    for j=2:2:echo_num
        origin_2D_complex(j,:)=fliplr(origin_2D_complex(j,:));%偶数行翻转
        origin_2D_complex(j,:) = circshift(origin_2D_complex(j,:),[0,-1]);%按列向左移动一位
        origin_2D_complex(j,length1)=0+1.0i*0;%第j行最后一个元素置零
    end
     both_img_noise=normrnd(0,sigma,echo_num,echo_num)+1.0i*normrnd(0,sigma,echo_num,echo_num);%生成正态分布的随机复数矩阵
     c= unifrnd(0.55,1.6);%产生一个随机的噪声权重系数
%      figure(200+w),imagesc(abs(origin_2D_complex))
     origin_2D_complex = origin_2D_complex + both_img_noise*c;
          
    expand_2D_complex=zeros(expand_num,expand_num)+1.0i*zeros(expand_num,expand_num);
    expand_2D_complex((expand_num-echo_num)/2+1:(expand_num+echo_num)/2,(expand_num-echo_num)/2+1:(expand_num+echo_num)/2)=origin_2D_complex;
   %所谓扩大就是把128的k空间直接放到256的中间，其余的点补零就好
    both_image_2D=fftshift(ifft2(ifftshift(expand_2D_complex)));%逆傅里叶变换
    both_image_2D_norm=both_image_2D/max(max(abs(both_image_2D)));%归一化
  
%     for ii=1:1:expand_num
%         for jj=1:1:expand_num
%             if(rot_T2(ii,jj)==0)
%                 both_image_2D_norm(ii,jj)=0;
%             end
%         end
%      end

%这里开始处理B1数据
    filename_2 = strcat(file,temp_B1(w,1).name);
    fip_B1=fopen(filename_2,'rb');
    [Array_2D_B1,num]=fread(fip_B1,inf,'double');
    data_B1=Array_2D_B1(:,:);
    pic_B1=reshape(data_B1,512,512);
    %         figure(10+w),imagesc(pic_B1');  
    T2_B1=imresize(pic_B1,[expand_num,expand_num],'bilinear');
    rot_B1=flipud(rot90(T2_B1,1));%先逆时针旋转90度，再上下翻转
    for ii=1:1:expand_num
        for jj=1:1:expand_num
            if(rot_T2(ii,jj)==0)
                rot_B1(ii,jj)=0;
            end
        end
    end
    %这里开始处理m0数据    
    filename_m0 = strcat(file,temp_m0(w,1).name);
    fip_m0=fopen(filename_m0,'rb');
    [Array_2D_m0,num]=fread(fip_m0,inf,'double');    
    data_m0=Array_2D_m0(:,:);
    pic_m0=reshape(data_m0,512,512);
    m0_2D=imresize(pic_m0,[expand_num,expand_num],'bilinear');%将512的图像resize变换成256
    if echo_num==128
        rot_m0=flipud(rot90(m0_2D,1));%和上面处理T2数据的过程一样
    else
        rot_m0=fliplr(rot90(m0_2D,1));
    end
    rot_m0=rot_m0*20;
    BW1_m0=edge(rot_m0,'canny',0.1);
    BW1_right_m0=circshift(BW1_m0,[0 1]);
    BW1_left_m0=circshift(BW1_m0,[0 -1]);
    BW1_up_m0=circshift(BW1_m0,[1 0]);
    BW1_down_m0=circshift(BW1_m0,[-1 0]);
    BW_all_m0=BW1_m0+BW1_right_m0+BW1_left_m0+BW1_up_m0+BW1_down_m0;
    BW2_m0=im2bw(BW_all_m0,0);    
    BW3_m0=~BW2_m0;%得到图像边缘
%     figure(300+w),imagesc(BW3);
%     mask(w + k1,:,:,2)=BW3_m0;
    mask(w + k1,:,:,1)=rot_B1;%B1数据
% 
% %     figure(400+w),imagesc(rot_m0); 
% 
    inpute(w + k1,:,:,1)=real(both_image_2D_norm);%输入数据的实部 temp文件求得
    inpute(w + k1,:,:,2)=imag(both_image_2D_norm);%输入数据的虚部 temp文件求得
    labels(w + k1,:,:,1)=rot_T2;%这里的T2是标签
%     labels(w + k1,:,:,2)=rot_m0;
%     labels(w + k1,:,:,1)=rot_B1;
    
%     figure(w+1000),imagesc(abs(both_image_2D_norm)); colormap jet
%     figure(w),imagesc(rot_T2,[0 0.19]); 
%     figure(w+10),imagesc(rot_m0,[0 0.5]); 
    figure(5000+w),imagesc(BW3_m0);
%     figure(w+500),imagesc(rot_B1,[0.8 1.2]); 
    fclose(fip_T2);
    fclose(fip_m0);
    fclose(fip_B1); 
    WJG_order = WJG_order+1;
    disp(WJG_order)
    end
    k1 = k1+k;
end
%这里是做的第二次修改
 save(['/data1/csj/data_2000/','350_m0_noise_6e7_035_16_only_T2.mat'], 'inpute','labels','mask','-v7.3')  
%  close all;
