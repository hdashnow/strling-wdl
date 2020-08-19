workflow SimpleVariantDiscovery {

  meta {
      author: "Harriet Dashnow"
      email: "h.dashnow@gmail.com"
      description: "Run STRling (github.com/quinlan-lab/STRling) in individual calling mode to detect and genotype STRs"
  }

  File manifest
  Array[Array[File]] sample_data = read_tsv(manifest)

  File strling
  File ref_fasta
  File ref_str

  scatter (sample_col in sample_data) {

    call str_extract {
      input:
        strling = strling,
        ref_fasta = ref_fasta,
        ref_str = ref_str,

        sample = sample_col[0],
        bam = sample_col[1],
        bam_index = sample_col[2],
    }

     call str_call_individual {
      input:
        strling = strling,
        ref_fasta = ref_fasta,
        ref_str = ref_str,
        bin = str_extract.bin,

        sample = sample_col[0],
        bam = sample_col[1],
        bam_index = sample_col[2],

    }

  }

}

task str_extract {
  File strling
  File ref_fasta
  File ref_str
  String sample
  File bam
  File bam_index

  command {
    ${strling} extract \
      -f ${ref_fasta} \
      -g ${ref_str} \
      ${bam} \
      ${sample}.bin
  }
  output {
    File bin = "${sample}.bin"
  }
}

task str_call_individual {
  File strling
  File ref_fasta
  File ref_str
  String sample
  File bam
  File bam_index
  File bin

  command {
    ${strling} extract \
      -f ${ref_fasta} \
      -g ${ref_str} \
      ${bam} \
      ${sample}.bin

    ${strling} call \
      -f ${ref_fasta} \
      -o ${sample} \
      ${bam} \
      ${bin}
  }
  output {
    File output_bounds = "${sample}-bounds.txt"
    File output_unplaced = "${sample}-unplaced.txt"
    File output_genotype = "${sample}-genotype.txt"
  }
}

