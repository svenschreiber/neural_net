#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "base.h"
#include "platform.h"
#include "win32_platform.c"
#include "mnist.c"

#define INPUTS 784
#define OUTPUTS 10
#define HIDDEN_LAYERS 2
#define NEURONS_PER_HIDDEN_LAYER 16
#define LEARNING_RATE 0.01f
#define MOMENTUM 0.9f

typedef struct Layer Layer;
struct Layer {
    f32 *activations;
    f32 *weights;
    f32 *delta_weights;
    f32 *errors;
    f32 *biases;
    u32 num_neurons;
};

typedef struct Neural_Network Neural_Network;
struct Neural_Network {
    Layer *layers;
    u32 num_hidden_layers;
    u32 num_neurons_per_hidden_layer;
    u32 num_outputs;
    u32 num_layers;
};

f32 get_random_f32_zero_to_one() {
    return ((f32) rand() / RAND_MAX) - 0.5f;
}

f32 relu(f32 x) {
    return x < 0.0f ? 0.0f : x;
}

f32 relu_prime(f32 x) {
    return (f32) (x > 0.0f);
}

f32 sigmoid(f32 x) {
    return 1.0f / (1.0f - expf(-x));
}

f32 sigmoid_prime(f32 x) {
    return x * (1.0f - x);
}

f32 softmax(Layer *layer, Layer *prev_layer, f32 label) {
    f32 max = layer->activations[0];
    for (u32 i = 0; i < layer->num_neurons; ++i) {
        if (layer->activations[i] > max) {
            max = layer->activations[i];
        }
    }

    f32 exp_sum = 0.0f;
    for (u32 i = 0; i < layer->num_neurons; ++i) {
        layer->activations[i] -= max;
        f32 exp_activation = expf(layer->activations[i]);
        exp_sum += exp_activation;
        layer->activations[i] = exp_activation;
    }

    for (u32 i = 0; i < layer->num_neurons; ++i) {
        layer->activations[i] /= exp_sum;
    }

    f32 loss = -logf(layer->activations[(s32) label]) / (f32) layer->num_neurons;

    return loss;
}

void init_neural_network(Neural_Network *net) {
    net->num_hidden_layers = HIDDEN_LAYERS;
    net->num_neurons_per_hidden_layer = NEURONS_PER_HIDDEN_LAYER;
    net->num_outputs = OUTPUTS;
    net->num_layers = HIDDEN_LAYERS + 2;

    srand((u32)time(NULL));

    net->layers = (Layer *)malloc(net->num_layers * sizeof(Layer));
    Layer *layers = net->layers;

    layers[0].num_neurons = INPUTS;
    layers[0].activations = (f32 *)malloc(layers[0].num_neurons * sizeof(f32));

    for (u32 i = 1; i < net->num_layers; ++i) {
        Layer *layer = &layers[i];
        Layer *prev_layer = &layers[i - 1];

        if (i != net->num_layers - 1) layer->num_neurons = net->num_neurons_per_hidden_layer;
        else                          layer->num_neurons = net->num_outputs;

        layer->activations = (f32 *)malloc(layer->num_neurons * sizeof(f32));
        layer->weights     = (f32 *)malloc(layer->num_neurons * prev_layer->num_neurons * sizeof(f32));
        layer->delta_weights = (f32 *)malloc(layer->num_neurons * prev_layer->num_neurons * sizeof(f32));
        layer->errors      = (f32 *)malloc(layer->num_neurons * sizeof(f32)); 
        layer->biases      = (f32 *)malloc(layer->num_neurons * sizeof(f32)); 

        for (u32 j = 0; j < layer->num_neurons; ++j) {
            for (u32 k = 0; k < prev_layer->num_neurons; ++k) {
                layer->weights[j * prev_layer->num_neurons + k] = get_random_f32_zero_to_one();
                layer->delta_weights[j * prev_layer->num_neurons + k] = 0.0f;
            }
            layer->biases[j] = get_random_f32_zero_to_one();
        }
    }
}

void load_into_input_layer(Neural_Network *net, f32 *inputs) {
    Layer *input_layer = net->layers;
    for (u32 i = 0; i < input_layer->num_neurons; ++i) {
        input_layer->activations[i] = inputs[i];
    }
}

u64 layer_argmax(Layer *layer) {
    f32 max = layer->activations[0];
    u64 max_idx = 0;
    for (u32 i = 0; i < layer->num_neurons; ++i) {
        if (layer->activations[i] > max) {
            max = layer->activations[i];
            max_idx = i;
        }
    }
    return max_idx;
}

f32 forward_propagate(Neural_Network *net, f32 label) {
    for (u32 i = 1; i < net->num_layers - 1; ++i) {
        Layer *layer = &net->layers[i];
        Layer *prev_layer = &net->layers[i - 1];

        for (u32 j = 0; j < layer->num_neurons; ++j) {
            f32 sum = layer->biases[j];
            for (u32 k = 0; k < prev_layer->num_neurons; ++k) {
                sum += prev_layer->activations[k] * layer->weights[j * prev_layer->num_neurons + k];
            }
            layer->activations[j] = relu(sum);
        }
    }

    Layer *layer = &net->layers[net->num_layers - 1];
    Layer *prev_layer = &net->layers[net->num_layers - 2];
    for (u32 i = 0; i < layer->num_neurons; ++i) {
        f32 sum = layer->biases[i];
        for (u32 j = 0; j < prev_layer->num_neurons; ++j) {
            sum += prev_layer->activations[j] * layer->weights[i * prev_layer->num_neurons + j];
        }
        layer->activations[i] = sum;
    }
    return softmax(layer, prev_layer, label);
}

void back_propagate(Neural_Network *net, f32 label) {
    Layer *layer = &net->layers[net->num_layers - 1];
    for (u32 i = 0; i < layer->num_neurons; ++i) {
        f32 is_label = (f32)(label == (f32)i);
        layer->errors[i] = layer->activations[i] - is_label;
    }

    for (s64 i = net->num_layers - 2; i > 0; --i) {
        layer = &net->layers[i];
        Layer *next_layer = &net->layers[i + 1];
        for (u32 j = 0; j < layer->num_neurons; ++j) {
            f32 error = 0.0f;
            for (u32 k = 0; k < next_layer->num_neurons; ++k) {
                error += next_layer->errors[k] * next_layer->weights[k * layer->num_neurons + j];
            }
            layer->errors[j] = error * relu_prime(layer->activations[j]);
        }
    }

    u64 weight_idx = 0;
    for (s64 i = net->num_layers - 1; i > 0; --i) {
        layer = &net->layers[i];
        Layer *prev_layer = &net->layers[i - 1];
        for (u32 j = 0; j < layer->num_neurons; ++j) {
            layer->biases[j] -= layer->errors[j] * LEARNING_RATE;
            for (u32 k = 0; k < prev_layer->num_neurons; ++k) {
                weight_idx = j * prev_layer->num_neurons + k;
                layer->delta_weights[weight_idx] = MOMENTUM * layer->delta_weights[weight_idx] + (1.0f - MOMENTUM) * prev_layer->activations[k] * layer->errors[j];
                layer->weights[weight_idx] -= layer->delta_weights[weight_idx] * LEARNING_RATE;
            }
        }
    }
}

void train(Neural_Network *net, u64 epochs) {
    MNIST_Dataset dataset = load_mnist();
    f32 *x_train = dataset.x_train;
    f32 *y_train = dataset.y_train;
    u32 dataset_size = 60000;

    f32 loss = 0.0f;
    u32 batch_size = dataset_size / 10;
    for (u64 i = 0; i < epochs; ++i) {
        printf("Epoch %llu\n", i);
        for (u32 j = 0; j < dataset_size; ++j) {
            f32 label = y_train[j];
            load_into_input_layer(net, &x_train[j * MNIST_IMG_BYTES]);
            loss += forward_propagate(net, label);
            if (j % batch_size == 0) {
                Layer *last_layer = &net->layers[net->num_layers - 1];
                printf("Loss: %f \t Ground-Truth: %u \t Prediction-Accuracy: %f\n", loss / batch_size, (u32)label, last_layer->activations[(s32)label]);
                loss = 0.0f;
            }

            back_propagate(net, label);
        }
    }
}

int main() {
    Neural_Network net;
    init_neural_network(&net);
    train(&net, 10);

    return 0;
}
