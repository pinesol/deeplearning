----------------------------------------------------------------------
-- This tutorial shows how to train different models on the MNIST
-- dataset using multiple optimization techniques (SGD, ASGD, CG), and
-- multiple types of models.
--
-- This script demonstrates a classical example of training 
-- well-known models (convnet, MLP, logistic regression)
-- on a 10-class classification problem. 
--
-- It illustrates several points:
-- 1/ description of the model
-- 2/ choice of a loss function (criterion) to minimize
-- 3/ creation of a dataset as a simple Lua table
-- 4/ description of training and test procedures
--
-- Clement Farabet
----------------------------------------------------------------------
require 'torch'

----------------------------------------------------------------------
print '==> processing options'

cmd = torch.CmdLine()
cmd:text()
cmd:text('MNIST Loss Function')
cmd:text()
cmd:text('Options:')
-- global:
cmd:option('-seed', 1, 'fixed input seed for repeatable experiments')
cmd:option('-threads', 2, 'number of threads')
-- data:
cmd:option('-size', 'tiny', 'how many samples do we load: small | full')
cmd:option('-tr_frac', 0.75, 'fraction of original train data assigned to validation ')
-- model:
cmd:option('-model', 'convnet', 'type of model to construct: linear | mlp | convnet')
-- loss:
cmd:option('-loss', 'nll', 'type of loss function to minimize: nll | mse | margin')
-- training:
cmd:option('-save', 'results', 'subdirectory to save/log experiments in')
cmd:option('-plot', false, 'live plot')
cmd:option('-optimization', 'SGD', 'optimization method: SGD | ASGD | CG | LBFGS')
cmd:option('-learningRate', 1e-3, 'learning rate at t=0')
cmd:option('-batchSize', 1, 'mini-batch size (1 = pure stochastic)')
cmd:option('-batchSizeArray', {1,10,50,100}, 'batch sizes to try')


cmd:option('-weightDecay', 0, 'weight decay (SGD only)')
cmd:option('-momentum', 0, 'momentum (SGD only)')
cmd:option('-t0', 1, 'start averaging at t0 (ASGD only), in nb of epochs')
cmd:option('-maxIter', 2, 'maximum nb of iterations for CG and LBFGS')
cmd:option('-type', 'double', 'type: double | float | cuda')
cmd:text()
opt = cmd:parse(arg or {})

-- nb of threads and fixed seed (for repeatable experiments)
if opt.type == 'float' then
   print('==> switching to floats')
   torch.setdefaulttensortype('torch.FloatTensor')
elseif opt.type == 'cuda' then
   print('==> switching to CUDA')
   require 'cunn'
   torch.setdefaulttensortype('torch.FloatTensor')
end
torch.setnumthreads(opt.threads)
torch.manualSeed(opt.seed)

--opt.save = opt.save .. opt.batchSize TO DO
----------------------------------------------------------------------
print '==> executing all'

dofile '1_data.lua'
dofile '2_model.lua'
dofile '3_loss.lua'
dofile '4_train.lua'
dofile '4b_validate.lua'
dofile '5_test.lua'

----------------------------------------------------------------------
print '==> training!'

-- global variables
epsilon = 0.000001
old_accuracy = 0
max_epochs = 15
epoch = 1
accuracy_tracker = {}

function start_logging()
   --train_new_name = 'train'..opt.batchSize..'.log'
   --print (train_new_name)
   trainLogger = optim.Logger(paths.concat(opt.save, 'train'..opt.batchSize..'.log'))
   valLogger = optim.Logger(paths.concat(opt.save, 'validate'..opt.batchSize..'.log'))  
   testLogger = optim.Logger(paths.concat(opt.save, 'test'..opt.batchSize..'.log'))
   ModelUpdateLogger = optim.Logger(paths.concat(opt.save, 'ModelUpdateLog'..opt.batchSize..'.log'))
   ModelUpdateLogger:setNames{'iteration saved', 'validation error'}
end

--start_logging()
--train(trainLogger)

function per_model(trainLogger,testLogger,ModelUpdateLogger)
   while epoch <= max_epochs do -- epoch is incremented in train function
      train(trainLogger)
      validate(testLogger,ModelUpdateLogger)
   end
end

function change_batch_size()
   for i = 1, #opt.batchSizeArray do
      -- set specific batchsize for expirement
      opt.batchSize = opt.batchSizeArray[i]
      -- change save path to folder for specific batchsize
      start_logging()
      per_model(trainLogger,testLogger,ModelUpdateLogger)
   end
end


change_batch_size()

-- print(accuracy_tracker) 

