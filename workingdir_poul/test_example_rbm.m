clear all
addpath(genpath('../'));
load PatchesData_8_8_1000000;
opts.batchsize = 100;

PATCHES = double(PATCHES(1:floor(size(PATCHES,1) / opts.batchsize) * opts.batchsize,:))/255;
%test_x  = double(test_x)/255;

%%  ex1 train a 100 hidden unit RBM and visualize its weights
rng(0);
dbn.sizes = [100];
opts.numepochs =   10;

opts.momentum  =   0.01;
opts.alpha     =   0.01;
dbn = dbnsetup(dbn, PATCHES, opts);
dbn = dbntrain(dbn, PATCHES, opts);
figure(1)
visualize_rgb(dbn.rbm{1}.W);
figure(2); visualize(dbn.rbm{1}.W(:,(1:8*8)+8*8)',[-1 1])
%%
% Use the SDAE to initialize a FFNN
nn = nnsetup([784 100 10]);
nn.activation_function              = 'sigm';
nn.learningRate                     = 1;
nn.W{1} = sae.ae{1}.W{1};

% Train the FFNN
opts.numepochs =   1;
opts.batchsize = 100;
[nn,L,loss] = nntrain(nn, train_x, train_y, opts);
[er, bad] = nntest(nn, test_x, test_y);
assert(er < 0.16, 'Too big error');

%% ex2 train a 100-100 hidden unit SDAE and use it to initialize a FFNN
%  Setup and train a stacked denoising autoencoder (SDAE)
rng(0);
sae = saesetup([784 100 100]);
sae.ae{1}.activation_function       = 'sigm';
sae.ae{1}.learningRate              = 1;
sae.ae{1}.inputZeroMaskedFraction   = 0.5;

sae.ae{2}.activation_function       = 'sigm';
sae.ae{2}.learningRate              = 1;
sae.ae{2}.inputZeroMaskedFraction   = 0.5;

opts.numepochs =   1;
opts.batchsize = 100;
sae = saetrain(sae, train_x, opts);
visualize(sae.ae{1}.W{1}',[-1 1])
display_network(sae.ae{1}.W{1}')

% Use the SDAE to initialize a FFNN
nn = nnsetup([784 100 100 10]);
nn.activation_function              = 'sigm';
nn.learningRate                     = 1;

%add pretrained weights
nn.W{1} = sae.ae{1}.W{1};
nn.W{2} = sae.ae{2}.W{1};

% Train the FFNN
opts.numepochs =   1;
opts.batchsize = 100;
[nn,L,loss] = nntrain(nn, train_x, train_y, opts);
[er, bad] = nntest(nn, test_x, test_y);
assert(er < 0.1, 'Too big error');
