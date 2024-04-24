NAME=alphafold
DOCKER_IMAGE=quay.io/hallamlab/external_$NAME
# DOCKER_IMAGE=quay.io/txyliu/$NAME
# DOCKER_IMAGE=quay.io/hallamlab/$NAME
VERSION=2.3.2
echo image: $DOCKER_IMAGE:$VERSION
echo ""

HERE=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

case $1 in
    --build|-b)
        # pre-download requirements
        mkdir -p $HERE/load
        cd $HERE/load
        TINI_VERSION=v0.19.0
        ! [ -f tini ] && wget https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini
        ! [ -d alphafold ] && git clone https://github.com/google-deepmind/alphafold
        ALPHAFOLD_COMMON="alphafold_common"
        ! [ -d $ALPHAFOLD_COMMON ] && wget -P $ALPHAFOLD_COMMON/ https://git.scicore.unibas.ch/schwede/openstructure/-/raw/7102c63615b64735c4941278d92b554ec94415f8/modules/mol/alg/src/stereo_chemical_props.txt
        cd $HERE

        # build the docker container locally
        MAMBA_VER="24.3.0-0"
        export DOCKER_BUILDKIT=1
        docker build \
            --build-arg="CONDA_ENV=${NAME}_env" \
            --build-arg="MAMBA_VER=${MAMBA_VER}" \
            -t $DOCKER_IMAGE .
    ;;
    --push|-p)
        # login and push image to quay.io, remember to change the python constants in src/
        # sudo docker login quay.io
	    docker push $DOCKER_IMAGE:latest
    ;;
    --sif)
        # test build singularity
        singularity build $NAME.sif docker-daemon://$DOCKER_IMAGE:latest
    ;;
    --run|-r)
        # test run docker image
            # --mount type=bind,source="$HERE/scratch/res",target="/ref"\
            # --mount type=bind,source="$HERE/scratch/res/.ncbi",target="/.ncbi" \
            # --mount type=bind,source="$HERE/test",target="/ws" \
            # -e XDG_CACHE_HOME="/ws"\
        
        ! [ -d $HERE/scratch ] && mkdir -p $HERE/scratch
        docker run -it --rm \
            --mount type=bind,source="$HERE/scratch",target="/ws" \
            --workdir="/ws" \
            -u $(id -u):$(id -g) \
            $DOCKER_IMAGE \
            /bin/bash 
    ;;
    -t)
        singularity run ./$NAME.sif bash
        # docker run -it --rm \
        #     --mount type=bind,source="$HERE/scratch",target="/ws"\
        #     --mount type=bind,source="$HERE/docker/lib",target="/app"\
        #     --mount type=bind,source="$HERE/docker/load/quipucamayoc/quipucamayoc",target="/opt/conda/envs/quipucamayoc/lib/python3.10/site-packages/quipucamayoc"\
        #     --workdir="/ws" \
        #     -u $(id -u):$(id -g) \
        #     $DOCKER_IMAGE \
        #     python /ws/test.py
        #     # /bin/bash 
    ;;
    *)
        echo "bad option"
        echo $1
    ;;
esac
