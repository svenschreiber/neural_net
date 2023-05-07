INPUTS :: 784;
OUTPUTS :: 10;
HIDDEN_LAYERS :: 2;
NEURONS_PER_HIDDEN_LAYER :: 16;
LEARNING_RATE :: 0.01;
MOMENTUM :: 0.9;

Layer :: struct {
    activations: *f32;
    weights: *f32;
    delta_weights: *f32;
    errors: *f32;
    biases: *f32;
    num_neurons: u32;
}

Neural_Network :: struct {
    layers: []Layer;
    num_hidden_layers: u32;
    num_neurons_per_hidden_layer: u32;
    num_outputs: u32;
    training: bool;
}

get_random_f32_zero_to_one :: () -> f32 {
    return (cast(f32) rand() / xx RAND_MAX) - 0.5;
}

relu :: (x: f32) -> f32 {
    if (x < 0.0) return 0.0; 
    return x;
}

relu_prime :: (x: f32) -> f32 {
    if (x <= 0.0) return 0.0;
    return 1.0;
}

sigmoid :: (x: f32) -> f32 {
    return 1.0 / (1.0 + expf(-x));
}

sigmoid_prime :: (x: f32) -> f32 {
    return x * (1.0 - x);
}

softmax :: (layer: *Layer, prev_layer: *Layer) {
    // get max for numerical stability
    max := layer.activations[0];
    for i := 1; i < layer.num_neurons; ++i {
        if layer.activations[i] > max {
            max = layer.activations[i];
        }
    }

    exp_sum: f32 = 0.0;
    for i := 0; i < layer.num_neurons; ++i {
        layer.activations[i] = expf(layer.activations[i] - max);
        exp_sum += layer.activations[i];
    }

    for i := 0; i < layer.num_neurons; ++i {
        layer.activations[i] /= exp_sum;
    }
}

cross_entropy_loss :: (layer: *Layer, label: u32) -> f32 {
    return -logf(layer.activations[label]);
}

init_neural_network :: (net: *Neural_Network) {
    net.num_hidden_layers = HIDDEN_LAYERS;
    net.num_neurons_per_hidden_layer = NEURONS_PER_HIDDEN_LAYER;
    net.num_outputs = OUTPUTS;

    srand(time(null));

    net.layers = allocate_array(*Default_Allocator, HIDDEN_LAYERS + 2, Layer);
    layers := net.layers;

    // Initialize the input layer
    layers[0].num_neurons = INPUTS;
    layers[0].activations = xx malloc(layers[0].num_neurons * size_of(f32));

    // Initialize all other layers
    for i := 1; i < layers.count; ++i {
        layer := *layers[i];
        prev_layer := *layers[i - 1];

        if (i != layers.count - 1) layer.num_neurons = net.num_neurons_per_hidden_layer;
        else                       layer.num_neurons = net.num_outputs;
        
        layer.activations   = xx malloc(layer.num_neurons * size_of(f32));
        layer.weights       = xx malloc(layer.num_neurons * prev_layer.num_neurons * size_of(f32));
        layer.delta_weights = xx calloc(layer.num_neurons * prev_layer.num_neurons, size_of(f32));
        layer.errors        = xx malloc(layer.num_neurons * size_of(f32)); 
        layer.biases        = xx malloc(layer.num_neurons * size_of(f32)); 

        for j := 0; j < layer.num_neurons; ++j {
            for k := 0; k < prev_layer.num_neurons; ++k {
                layer.weights[j * prev_layer.num_neurons + k] = get_random_f32_zero_to_one();
            }
            layer.biases[j] = get_random_f32_zero_to_one();
        }
    }
}

train :: (net: *Neural_Network, epochs: u64) {
    dataset := load_mnist();
    x_train := dataset.x_train;
    y_train := dataset.y_train;

    loss: f32 = 0;
    update_interval := 6000;
    for i: u64 = 0; i < epochs; ++i {
        print("Epoch: %\n", i);
        for j := 0; j < y_train.count; ++j {
            label := mnist_get_label(j, y_train);
            load_into_input_layer(net, mnist_get_image(j, x_train));
            forward_propagate(net);
            loss += cross_entropy_loss(*net.layers[net.layers.count - 1], xx label);
            if j % update_interval == 0 {
                last_layer := *net.layers[net.layers.count - 1];
                print("loss: % \t ground-truth: % \t certainty: %\n", loss / xx update_interval, label, last_layer.activations[cast(s32)label]);
                loss = 0.0;
            }
            back_propagate(net, label);
        }
    }
    test_loss, test_acc := test_evaluate(net, dataset.x_test, dataset.y_test);
    print("Evaluation --- loss: % \t acc: %\n", test_loss, test_acc);
    net.training = false;
}

predict :: (net: *Neural_Network, data: *f32) -> u64 {
    load_into_input_layer(net, data);
    forward_propagate(net);
    return layer_argmax(*net.layers[net.layers.count - 1]);
}

test_evaluate :: (net: *Neural_Network, x_test: []f32, y_test: []f32) -> f32, f32 {
    test_loss: f32 = 0.0;
    num_correct := 0;
    for i := 0; i < y_test.count; ++i {
        label := y_test[i];
        prediction := predict(net, mnist_get_image(i, x_test));
        test_loss += cross_entropy_loss(*net.layers[net.layers.count - 1], xx label);
        if prediction == xx label ++num_correct;
    }
    return test_loss / xx y_test.count, cast(f32)num_correct / xx y_test.count;
}

load_into_input_layer :: (net: *Neural_Network, inputs: *f32) {
    input_layer := *net.layers[0];
    for i := 0; i < input_layer.num_neurons; ++i {
        input_layer.activations[i] = inputs[i];
    }
}

layer_argmax :: (layer: *Layer) -> u64 {
    max := layer.activations[0];
    max_idx := 0;
    for i := 1; i < layer.num_neurons; ++i {
        if layer.activations[i] > max {
            max = layer.activations[i];
            max_idx = i;
        }
    }
    return max_idx;
}

forward_propagate :: (net: *Neural_Network) {
    // hidden
    for i := 1; i < net.layers.count - 1; ++i {
        layer := *net.layers[i];
        prev_layer := *net.layers[i - 1];
        for j := 0; j < layer.num_neurons; ++j {
            sum: f32 = layer.biases[j]; 
            for k := 0; k < prev_layer.num_neurons; ++k {
                sum += prev_layer.activations[k] * layer.weights[j * prev_layer.num_neurons + k];
            }
            layer.activations[j] = relu(sum);
        }
    }

    // output
    layer := *net.layers[net.layers.count - 1];
    prev_layer := *net.layers[net.layers.count - 2];
    for i := 0; i < layer.num_neurons; ++i {
        sum: f32 = layer.biases[i]; 
        for j := 0; j < prev_layer.num_neurons; ++j {
            sum += prev_layer.activations[j] * layer.weights[i * prev_layer.num_neurons + j];
        }
        layer.activations[i] = sum;
    }
    softmax(layer, prev_layer);
}

back_propagate :: (net: *Neural_Network, label: f32) {
    // Calculate the output error
    layer := *net.layers[net.layers.count - 1];
    for i := 0; i < layer.num_neurons; ++i {
        is_label := label == xx i;
        layer.errors[i] = layer.activations[i] - xx is_label;
    }

    // Propagate the error back through all of the hidden layers
    for i: s64 = net.layers.count - 2; i > 0; --i {
        layer = *net.layers[i];
        next_layer := *net.layers[i + 1];
        for j := 0; j < layer.num_neurons; ++j {
            error: f32 = 0.0;
            for k := 0; k < next_layer.num_neurons; ++k {
                error += next_layer.errors[k] * next_layer.weights[k * layer.num_neurons + j];
            }
            layer.errors[j] = error * relu_prime(layer.activations[j]);
        }
    }

    // Update weights according to their error and learning rate
    weight_idx: u64;
    for i: s64 = net.layers.count - 1; i > 0; --i {
        layer = *net.layers[i];
        prev_layer := *net.layers[i - 1];
        for j := 0; j < layer.num_neurons; ++j {
            layer.biases[j] -= layer.errors[j] * xx LEARNING_RATE;
            for k := 0; k < prev_layer.num_neurons; ++k {
                weight_idx = j * prev_layer.num_neurons + k;
                layer.delta_weights[weight_idx] = xx MOMENTUM * layer.delta_weights[weight_idx] + (1.0 - xx MOMENTUM) * prev_layer.activations[k] * layer.errors[j];
                layer.weights[weight_idx] -=  layer.delta_weights[weight_idx] * xx LEARNING_RATE;
            }
        }
    }
}
