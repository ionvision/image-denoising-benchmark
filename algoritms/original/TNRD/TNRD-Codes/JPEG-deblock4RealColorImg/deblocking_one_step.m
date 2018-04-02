function z = deblocking_one_step(input, Q_upper, Q_lower, model, pad, crop)
mfsAll = model.mfsAll;
K = model.K;
mfs = model.mfs;
filtN = length(K);

%% do a gradient descent step for all samples
bs = 8;
T = dctmtx(bs);
invdct = @(block_struct) T' * block_struct.data * T;
dct = @(block_struct) T * block_struct.data * T';

u = pad(input);
[r, c] = size(u);
g = 0;
parfor i=1:filtN
    Ku = imfilter(u,K{i},'symmetric');
%     Ne1 = lut_eval(Ku(:)', mfs.offsetD, mfs.step, mfsAll{i}.P, 0, 0, 0);
    Ne1 = lut_eval_one_variable(Ku(:)', mfs.offsetD, mfs.step, mfsAll{i}.P);
    Ne1 = reshape(Ne1,r,c);
    g = g + imfilter(Ne1,rot90(rot90(K{i})),'symmetric');
end
x = input - crop(g);
%% projection to QCS, truncate cofs
dct_x = blockproc(x,[bs bs],dct);
t_dct_x = max(Q_lower, min(Q_upper, dct_x));
z = blockproc(t_dct_x,[bs bs],invdct);

z = max(-128, min(z, 127));