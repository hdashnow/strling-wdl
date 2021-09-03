workflow strling_joint {

  meta {
      author: "Harriet Dashnow"
      email: "h.dashnow@gmail.com"
      description: "Run STRling (github.com/quinlan-lab/STRling) in joint calling mode to detect and genotype STRs"
  }

  # manifest is tsv with columns sample_id, cram and crai
  File manifest
  Array[Array[File]] sample_data = read_tsv(manifest)
  File ref_fasta
  File ref_str

  scatter (sample in sample_data) {

    call str_extract {
      input:
        ref_fasta = ref_fasta,
        ref_str = ref_str,
        cram = sample[1],
        crai = sample[2],
    }

  }

  call str_merge {
    input:
      ref_fasta = ref_fasta,
      bins = str_extract.bin,
  }

  scatter (pair in zip(sample_data, str_extract.bin)) {

     call str_call_joint {
      input:
        ref_fasta = ref_fasta,
        ref_str = ref_str,
        bounds = str_merge.bounds,
        cram = pair.left[1],
        crai = pair.left[2],
        bin = pair.right,
    }

  }

  call str_outlier {
    input:
      genotypes = str_call_joint.output_genotype,
      unplaceds = str_call_joint.output_unplaced,
  }

}

task str_extract {
  File ref_fasta
  File ref_str
  File cram
  File crai
  String sample = basename(cram, ".cram")

  command {
    strling extract \
      -f ${ref_fasta} \
      -g ${ref_str} \
      ${cram} \
      ${sample}.bin
  }
  runtime {
    memory: "4 GB"
    cpu: 1
    disks: "local-disk 100 HDD"
    preemptible: 3
    docker: "quay.io/biocontainers/strling:0.5.0--h14cfee4_0"
  }
  output {
    File bin = "${sample}.bin"
  }
}

task str_merge {
  File ref_fasta
  Array[File] bins

  command {
    strling merge \
      -f ${ref_fasta} \
      ${sep=' ' bins}
  }
  runtime {
    memory: "4 GB"
    cpu: 1
    disks: "local-disk 100 HDD"
    preemptible: 3
    docker: "quay.io/biocontainers/strling:0.5.0--h14cfee4_0"
  }
  output {
    File bounds = "strling-bounds.txt"
  }
}

task str_call_joint {
  File ref_fasta
  File ref_str
  File cram
  File bin
  File crai
  String sample = basename(cram, ".cram")
  File bounds

  command {
    strling call \
      -f ${ref_fasta} \
      -b ${bounds} \
      -o ${sample} \
      ${cram} \
      ${bin}
  }
  runtime {
    memory: "4 GB"
    cpu: 1
    disks: "local-disk 100 HDD"
    preemptible: 3
    docker: "quay.io/biocontainers/strling:0.5.0--h14cfee4_0"
  }
  output {
    File output_bounds = "${sample}-bounds.txt"
    File output_unplaced = "${sample}-unplaced.txt"
    File output_genotype = "${sample}-genotype.txt"
  }
}

task str_outlier {
  Array[File] genotypes
  Array[File] unplaceds

  command {
    strling-outliers.py \
      --genotypes ${sep=' ' genotypes} \
      --unplaced ${sep=' ' unplaceds} \
      --emit control-file.tsv
  }
  runtime {
    memory: "32 GB"
    cpu: 1
    disks: "local-disk 100 HDD"
    preemptible: 3
    docker: "quay.io/biocontainers/strling:0.5.0--h14cfee4_0"
  }
  output {
    File str_outliers = "STRs.tsv"
  }
}
