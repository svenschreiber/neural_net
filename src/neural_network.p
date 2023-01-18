INPUTS :: 784;
OUTPUTS :: 10;
HIDDEN_LAYERS :: 1;
NEURONS_PER_HIDDEN_LAYER :: 64;
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
}

get_random_f32_zero_to_one :: () -> f32 {
    return cast(f32) rand() / xx RAND_MAX;
}


/* Activation functions */
relu :: (x: f32) -> f32 {
    if x < 0.0 {
        return 0.0;
    }
    return x;
}

relu_prime :: (x: f32) -> f32 {
    if x <= 0.0 {
        return 0.0;
    }
    return 1.0;
}

sigmoid :: (x: f32) -> f32 {
    return 1.0 / (1.0 + expf(-x));
}

sigmoid_prime :: (x: f32) -> f32 {
    return x * (1.0 - x);
}

softmax :: (layer: *Layer, prev_layer: *Layer, label: f32) -> f32 {
    // get max for stability
    max := layer.activations[0];
    for i := 1; i < layer.num_neurons; ++i {
        if layer.activations[i] > max {
            max = layer.activations[i];
        }
    }

    // calc exp sum
    exp_sum: f32 = 0.0;
    for i := 0; i < layer.num_neurons; ++i {
        layer.activations[i] -= max;
        exp_activation := expf(layer.activations[i]);
        exp_sum += exp_activation;
        layer.activations[i] = exp_activation;
    }

    // calc softmax for each neuron
    for i := 0; i < layer.num_neurons; ++i {
        layer.activations[i] = layer.activations[i] / exp_sum;
    }

    // calc loss
    loss := -logf(layer.activations[cast(s32) label]) / xx layer.num_neurons;

    return loss;
}

abs_f64 :: (x: f32) -> f32 {
    if x < 0 return -x;
    return x;
}

init_neural_network :: (net: *Neural_Network) {
    net.num_hidden_layers = HIDDEN_LAYERS;
    net.num_neurons_per_hidden_layer = NEURONS_PER_HIDDEN_LAYER;
    net.num_outputs = OUTPUTS;

    srand(time(null));

    net.layers = allocate_array(HIDDEN_LAYERS + 2, Layer);
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
        
        layer.activations = xx malloc(layer.num_neurons * size_of(f32));
        layer.weights     = xx malloc(layer.num_neurons * prev_layer.num_neurons * size_of(f32));
        layer.delta_weights = xx malloc(layer.num_neurons * prev_layer.num_neurons * size_of(f32));
        layer.errors      = xx malloc(layer.num_neurons * size_of(f32)); 
        layer.biases      = xx malloc(layer.num_neurons * size_of(f32)); 

        for j := 0; j < layer.num_neurons; ++j {
            for k := 0; k < prev_layer.num_neurons; ++k {
                layer.weights[j * prev_layer.num_neurons + k] = get_random_f32_zero_to_one();
                layer.delta_weights[j * prev_layer.num_neurons + k] = 0.0;
            }
            layer.biases[j] = get_random_f32_zero_to_one();
        }
    }
}

train :: (net: *Neural_Network, epochs: u64) {
    dataset := load_mnist();
    x_train := *dataset.x_train[0];
    y_train := *dataset.y_train[0];
    dataset_size := 5000;

    loss: f32 = 0.0;
    batch_size := dataset_size / 10;
    for i: u64 = 0; i < epochs; ++i {
        for j := 0; j < dataset_size; ++j {
            label := y_train[j];
            load_into_input_layer(net, *x_train[j]);
            loss += forward_propagate(net, label);
            if j % batch_size == 0 {
                last_layer := *net.layers[net.layers.count - 1];
                print("Loss: % \t Ground-Truth: % \t Prediction-Accuracy: %\n", loss / xx batch_size, label, last_layer.activations[cast(s32)label]);
                loss = 0.0;
            }

            back_propagate(net, label);
        }
    }
}

load_into_input_layer :: (net: *Neural_Network, inputs: *f32) {
    input_layer := *net.layers[0];
    for i := 0; i < input_layer.num_neurons; ++i {
        input_layer.activations[i] = inputs[i];
    }
}

forward_propagate :: (net: *Neural_Network, label: f32) -> f32 {
    // hidden
    for i := 1; i < net.layers.count - 1; ++i {
        layer := *net.layers[i];
        prev_layer := *net.layers[i - 1];
        // For each neuron sum all the activations from the previous layer multiplied with their respective weights
        // and propagate these activation values forward through the whole network.
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
    return softmax(layer, prev_layer, label);
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
